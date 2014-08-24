[
  rule => {
    location => 'station',
    state => 'docked',
    is => cargo => [],
    perform => 'undock',
  },
  action => {
    name => 'undock',
    while => 'undocking',
    duration => 5, # steps
    result => [
        set(state => 'undocked'),
    ],
  },
  rule => {
    location => 'station',
    state => 'undocked',
    is => cargo => [],
    perform => 'travel',
  },
  action => {
    name => 'travel',
    while => 'travelling',
    duration => 7, # steps
    result => [
        set(state => 'arrived'),
    ],
  },
]
