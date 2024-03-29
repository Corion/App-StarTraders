'use strict';

// First, check for JSON support
// If there is no JSON, we no-op the core features of Raven
// since JSON is required to encode the payload
var _Raven = window.Raven,
    hasJSON = !!(window.JSON && window.JSON.stringify),
    globalServer,
    globalUser,
    globalKey,
    globalProject,
    globalOptions = {
        logger: 'javascript',
        ignoreErrors: [],
        ignoreUrls: [],
        whitelistUrls: [],
        includePaths: [],
        tags: {},
        extra: {}
    };

var TK = TraceKit.noConflict();

// Disable Tracekit's remote fetching by default
TK.remoteFetching = false;

/*
 * The core Raven singleton
 *
 * @this {Raven}
 */
var Raven = {
    VERSION: '<%= pkg.version %>',

    // Expose TraceKit to the Raven namespace
    TraceKit: TK,

    /*
     * Allow Raven to be configured as soon as it is loaded
     * It uses a global RavenConfig = {dsn: '...', config: {}}
     *
     * @return undefined
     */
    afterLoad: function() {
        var globalConfig = window.RavenConfig;
        if (globalConfig) {
            this.config(globalConfig.dsn, globalConfig.config).install();
        }
    },

    /*
     * Allow multiple versions of Raven to be installed.
     * Strip Raven from the global context and returns the instance.
     *
     * @return {Raven}
     */
    noConflict: function() {
        window.Raven = _Raven;
        return Raven;
    },

    /*
     * Configure Raven with a DSN and extra options
     *
     * @param {string} dsn The public Sentry DSN
     * @param {object} options Optional set of of global options [optional]
     * @return {Raven}
     */
    config: function(dsn, options) {
        var uri = parseUri(dsn),
            lastSlash = uri.path.lastIndexOf('/'),
            path = uri.path.substr(1, lastSlash);

        // merge in options
        if (options) {
            each(options, function(key, value){
                globalOptions[key] = value;
            });
        }

        // join regexp rules into one big rule
        globalOptions.ignoreUrls = globalOptions.ignoreUrls.length ? joinRegExp(globalOptions.ignoreUrls) : false;
        globalOptions.whitelistUrls = globalOptions.whitelistUrls.length ? joinRegExp(globalOptions.whitelistUrls) : false;
        globalOptions.includePaths = joinRegExp(globalOptions.includePaths);

        // "Script error." is hard coded into browsers for errors that it can't read.
        // this is the result of a script being pulled in from an external domain and CORS.
        globalOptions.ignoreErrors.push('Script error.');
        globalOptions.ignoreErrors.push('Script error');

        globalKey = uri.user;
        globalProject = ~~uri.path.substr(lastSlash + 1);

        // assemble the endpoint from the uri pieces
        globalServer = '//' + uri.host +
                      (uri.port ? ':' + uri.port : '') +
                      '/' + path + 'api/' + globalProject + '/store/';

        if (uri.protocol) {
            globalServer = uri.protocol + ':' + globalServer;
        }

        if (globalOptions.fetchContext) {
            TK.remoteFetching = true;
        }

        if (globalOptions.linesOfContext) {
            TK.linesOfContext = globalOptions.linesOfContext;
        }

        // return for chaining
        return Raven;
    },

    /*
     * Installs a global window.onerror error handler
     * to capture and report uncaught exceptions.
     * At this point, install() is required to be called due
     * to the way TraceKit is set up.
     *
     * @return {Raven}
     */
    install: function() {
        if (!isSetup()) return;

        TK.report.subscribe(handleStackInfo);

        return Raven;
    },

    /*
     * Wrap code within a context so Raven can capture errors
     * reliably across domains that is executed immediately.
     *
     * @param {object} options A specific set of options for this context [optional]
     * @param {function} func The callback to be immediately executed within the context
     * @param {array} args An array of arguments to be called with the callback [optional]
     */
    context: function(options, func, args) {
        if (isFunction(options)) {
            args = func || [];
            func = options;
            options = undefined;
        }

        return Raven.wrap(options, func).apply(this, args);
    },

    /*
     * Wrap code within a context and returns back a new function to be executed
     *
     * @param {object} options A specific set of options for this context [optional]
     * @param {function} func The function to be wrapped in a new context
     * @return {function} The newly wrapped functions with a context
     */
    wrap: function(options, func) {
        // options is optional
        if (isFunction(options)) {
            func = options;
            options = undefined;
        }

        var property,
            wrappedFunction = function() {
                try {
                    return func.apply(this, arguments);
                } catch(e) {
                    Raven.captureException(e, options);
                    throw e;
                }
            };

        for (property in func) {
            if (func.hasOwnProperty(property)) {
                wrappedFunction[property] = func[property];
            }
        }

        return wrappedFunction;
    },

    /*
     * Uninstalls the global error handler.
     *
     * @return {Raven}
     */
    uninstall: function() {
        TK.report.unsubscribe(handleStackInfo);

        return Raven;
    },

    /*
     * Manually capture an exception and send it over to Sentry
     *
     * @param {error} ex An exception to be logged
     * @param {object} options A specific set of options for this error [optional]
     * @return {Raven}
     */
    captureException: function(ex, options) {
        // If a string is passed through, recall as a message
        if (typeof ex === 'string') {
            return Raven.captureMessage(ex, options);
        }

        // TraceKit.report will re-raise any exception passed to it,
        // which means you have to wrap it in try/catch. Instead, we
        // can wrap it here and only re-raise if TraceKit.report
        // raises an exception different from the one we asked to
        // report on.
        try {
            TK.report(ex, options);
        } catch(ex1) {
            if(ex !== ex1) {
                throw ex1;
            }
        }

        return Raven;
    },

    /*
     * Manually send a message to Sentry
     *
     * @param {string} msg A plain message to be captured in Sentry
     * @param {object} options A specific set of options for this message [optional]
     * @return {Raven}
     */
    captureMessage: function(msg, options) {
        // Fire away!
        send(
            arrayMerge({
                message: msg
            }, options)
        );

        return Raven;
    },

    /*
     * Set/clear a user to be sent along with the payload.
     *
     * @param {object} user An object representing user data [optional]
     * @return {Raven}
     */
    setUser: function(user) {
       globalUser = user;

       return Raven;
    }
};

function triggerEvent(eventType, options) {
    var event, key;

    eventType = 'raven' + eventType.substr(0,1).toUpperCase() + eventType.substr(1);

    if (document.createEvent) {
        event = document.createEvent('HTMLEvents');
        event.initEvent(eventType, true, true);
    } else {
        event = document.createEventObject();
        event.eventType = eventType;
    }

    if (typeof options !== 'object') {
        options = {};
    }

    for (key in options) if (options.hasOwnProperty(key)) {
        event[key] = options[key];
    }

    if (document.createEvent) {
        // IE9 if standards
        document.dispatchEvent(event);
    } else {
        // IE8 regardless of Quirks or Standards
        // IE9 if quirks
        try {
            document.fireEvent('on' + event.eventType.toLowerCase(), event);
        } catch(e) {}
    }
}

var uriKeys = 'source protocol authority userInfo user password host port relative path directory file query anchor'.split(' '),
    uriPattern = /^(?:(?![^:@]+:[^:@\/]*@)([^:\/?#.]+):)?(?:\/\/)?((?:(([^:@]*)(?::([^:@]*))?)?@)?([^:\/?#]*)(?::(\d*))?)(((\/(?:[^?#](?![^?#\/]*\.[^?#\/.]+(?:[?#]|$)))*\/?)?([^?#\/]*))(?:\?([^#]*))?(?:#(.*))?)/;

/**** Private functions ****/
function parseUri(str) {
    var m = uriPattern.exec(str),
        uri = {},
        i = 14;

    while (i--) uri[uriKeys[i]] = m[i] || '';

    return uri;
}

function isUndefined(what) {
    return typeof what === 'undefined';
}

function isFunction(what) {
    return typeof what === 'function';
}

function each(obj, callback) {
    var i, j;

    if (isUndefined(obj.length)) {
        for (i in obj) {
            if (obj.hasOwnProperty(i)) {
                callback.call(null, i, obj[i]);
            }
        }
    } else {
        j = obj.length;
        if (j) {
            for (i = 0; i < j; i++) {
                callback.call(null, i, obj[i]);
            }
        }
    }
}

var cachedAuth;

function getAuthQueryString() {
    if (cachedAuth) return cachedAuth;

    var qs = [
        'sentry_version=3',
        'sentry_client=raven-js/' + Raven.VERSION
    ];
    if (globalKey) {
        qs.push('sentry_key=' + globalKey);
    }

    cachedAuth = '?' + qs.join('&');
    return cachedAuth;
}

function handleStackInfo(stackInfo, options) {
    var frames = [];

    if (stackInfo.stack && stackInfo.stack.length) {
        each(stackInfo.stack, function(i, stack) {
            var frame = normalizeFrame(stack);
            if (frame) {
                frames.push(frame);
            }
        });
    }

    triggerEvent('handle', {
        stackInfo: stackInfo,
        options: options
    });

    processException(
        stackInfo.name,
        stackInfo.message,
        stackInfo.url,
        stackInfo.lineno,
        frames,
        options
    );
}

function normalizeFrame(frame) {
    if (!frame.url) return;

    // normalize the frames data
    var normalized = {
        filename:   frame.url,
        lineno:     frame.line,
        colno:      frame.column,
        'function': frame.func || '?'
    }, context = extractContextFromFrame(frame), i;

    if (context) {
        var keys = ['pre_context', 'context_line', 'post_context'];
        i = 3;
        while (i--) normalized[keys[i]] = context[i];
    }

    normalized.in_app = !( // determine if an exception came from outside of our app
        // first we check the global includePaths list.
        !globalOptions.includePaths.test(normalized.filename) ||
        // Now we check for fun, if the function name is Raven or TraceKit
        /(Raven|TraceKit)\./.test(normalized['function']) ||
        // finally, we do a last ditch effort and check for raven.min.js
        /raven\.(min\.)js$/.test(normalized.filename)
    );

    return normalized;
}

function extractContextFromFrame(frame) {
    // immediately check if we should even attempt to parse a context
    if (!frame.context || !globalOptions.fetchContext) return;

    var context = frame.context,
        pivot = ~~(context.length / 2),
        i = context.length, isMinified = false;

    while (i--) {
        // We're making a guess to see if the source is minified or not.
        // To do that, we make the assumption if *any* of the lines passed
        // in are greater than 300 characters long, we bail.
        // Sentry will see that there isn't a context
        if (context[i].length > 300) {
            isMinified = true;
            break;
        }
    }

    if (isMinified) {
        // The source is minified and we don't know which column. Fuck it.
        if (isUndefined(frame.column)) return;

        // If the source is minified and has a frame column
        // we take a chunk of the offending line to hopefully shed some light
        return [
            [],  // no pre_context
            context[pivot].substr(frame.column, 50), // grab 50 characters, starting at the offending column
            []   // no post_context
        ];
    }

    return [
        context.slice(0, pivot),    // pre_context
        context[pivot],             // context_line
        context.slice(pivot + 1)    // post_context
    ];
}

function processException(type, message, fileurl, lineno, frames, options) {
    var stacktrace, label, i;

    // IE8 really doesn't have Array.prototype.indexOf
    // Filter out a message that matches our ignore list
    i = globalOptions.ignoreErrors.length;
    while (i--) {
        if (message === globalOptions.ignoreErrors[i]) {
            return;
        }
    }

    if (frames && frames.length) {
        stacktrace = {frames: frames};
        fileurl = fileurl || frames[0].filename;
    } else if (fileurl) {
        stacktrace = {
            frames: [{
                filename: fileurl,
                lineno: lineno
            }]
        };
    }

    if (globalOptions.ignoreUrls && globalOptions.ignoreUrls.test(fileurl)) return;
    if (globalOptions.whitelistUrls && !globalOptions.whitelistUrls.test(fileurl)) return;

    label = lineno ? message + ' at ' + lineno : message;

    // Fire away!
    send(
        arrayMerge({
            'sentry.interfaces.Exception': {
                type: type,
                value: message
            },
            'sentry.interfaces.Stacktrace': stacktrace,
            culprit: fileurl,
            message: label
        }, options)
    );
}

function arrayMerge(arr1, arr2) {
    if (!arr2) {
        return arr1;
    }
    each(arr2, function(key, value){
        arr1[key] = value;
    });
    return arr1;
}

function getHttpData() {
    var http = {
        url: document.location.href,
        headers: {
            'User-Agent': navigator.userAgent
        }
    };

    if (document.referrer) {
        http.headers.Referer = document.referrer;
    }

    return http;
}

function send(data) {
    if (!isSetup()) return;

    data = arrayMerge({
        project: globalProject,
        logger: globalOptions.logger,
        site: globalOptions.site,
        platform: 'javascript',
        'sentry.interfaces.Http': getHttpData()
    }, data);

    // Merge in the tags and extra separately since arrayMerge doesn't handle a deep merge
    data.tags = arrayMerge(globalOptions.tags, data.tags);
    data.extra = arrayMerge(globalOptions.extra, data.extra);

    // If there are no tags/extra, strip the key from the payload alltogther.
    if (!data.tags) delete data.tags;
    if (!data.extra) delete data.extra;

    if (globalUser) data['sentry.interfaces.User'] = globalUser;

    if (isFunction(globalOptions.dataCallback)) {
        data = globalOptions.dataCallback(data);
    }

    // Check if the request should be filtered or not
    if (isFunction(globalOptions.shouldSendCallback) && !globalOptions.shouldSendCallback(data)) {
        return;
    }

    makeRequest(data);
}


function makeRequest(data) {
    var img, src;

    function success() {
        triggerEvent('success', {
            data: data,
            src: src
        });
    }

    function failure() {
        triggerEvent('failure', {
            data: data,
            src: src
        });
    }

    src = globalServer + getAuthQueryString() + '&sentry_data=' + encodeURIComponent(JSON.stringify(data));
    img = new Image();
    img.onload = success;
    img.onerror = failure;
    img.onabort = failure;
    img.src = src;
}

function isSetup() {
    if (!hasJSON) return false;  // needs JSON support
    if (!globalServer) {
        if (window.console && console.error) {
            console.error("Error: Raven has not been configured.");
        }
        return false;
    }
    return true;
}

function wrapArguments(what) {
    if (!isFunction(what)) return what;

    function wrapped() {
        var args = [], i = arguments.length, arg;
        while(i--) {
            arg = arguments[i];
            args[i] = isFunction(arg) ? Raven.wrap(arg) : arg;
        }
        what.apply(null, args);
    }
    // copy over properties of the old function
    for (var k in what) wrapped[k] = what[k];
    return wrapped;
}

function joinRegExp(patterns) {
    // Combine an array of regular expressions into one large regexp
    var sources = [], i = patterns.length;
    // lol, map
    while (i--) sources[i] = patterns[i].source;
    return new RegExp(sources.join('|'), 'i');
}

Raven.afterLoad();
