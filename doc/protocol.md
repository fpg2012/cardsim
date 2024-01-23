# Protocol

> version `0.1.1`

## Overview

1. based on websocket
2. game states are stored on server
3. valid requests sent to the server should be responded explicitly with acceptions or rejections
4. timeouts imply rejections
5. operations accepted by server will be relayed to every other client, while operations rejected will not by relayed
6. most requests sent by client should contains its `id_` and `token`
7. all requests sent by client should contain a unique `seq` number which should be contained in corrisponding responses
8. server should ignore all requests whose id and token are not match

There are 8 basic types of packets:

1. Join: sent by client at first join
2. Quit: sent by client when quitting
3. Rejoin: sent by client to restore the last join
4. Operate: sent by client to do some operation
5. Message: sent by client to convey some messages
6. Accept: sent by server to acknowledge some request
7. Reject: sent by server to reject some request
8. Event: sent by server when something happens on server

## Conventions

1. `"xxx"`, `"yyy"`, `"zzz"` imply some UTF-8 String
2. `N`, `M`, `P`, `Q`, `X`, `Y`, `Z` imply some Integer
3. `{x}` implies some object
4. `[[ ]]` implies the field is nullable
5. `null` field is equavelant to the absence
6. `|` means or

## Join

- path: CLIENT -> SERVER -> Other CLIENTS
- when: CLIENT's first join

### Content

sent by CLIENT:

```
{
    "type": "join",
    "username": "xxx",
    "id_": 0,
    "room_id_": R,
    "token": 0,
    "seq": N
}
```

> if `room_id_` is 0, server will create a new room

accepcted:

```
{
    "type": "accpet",
    "data": {
        "id_": P,
        "token": Q,
        "ack-seq": N,
        "game-state": {x},
        "room_id_": R
    }
}
```

rejected:

```
{
    "type: "reject",
    "ack_seq": N,
    "reason": [["xxx"]]
}
```

or IGNORE

relayed:

```
{
    "type": "event",
    "event": "join",
    "data": {
        "username": "xxx",
        "id_": P
    },
    "seq": M
}
```

### Possible reasons for rejections

| reason            |                        |
| ----------------- | ---------------------- |
| `"username_used"` | username has been used |
| `"room_invalid"`  | room_id_ is invalid    |
| `null`            | others                 |

## Quit

- path: CLIENT -> SERVER -> Other CLIENTS
- when: CLIENT decide to leave

sent by CLIENT:

```
{
    "type": "quit",
    "id_": P,
    "token": Q,
    "seq": N
}
```

accepted:

```
{
    "type": "accept",
    "ack_seq": N
}
```

rejected:

IGNORE

relayed:

```
{
    "type": "event",
    "event": "quit",
    "data": {
        "id_": P
    }
    "seq": M
}
```

## Kick

- path: CLIENT -> SERVER -> Other CLIENTS

- when: CLIENT (room admin) decided to kick a CLIENT

sent by CLIENT:

```

```

{
    "type": "kick",
    "id_": P,
    "to_kick_id_": P',
    "token": Q,
    "seq": N
}

```

```

accepted:

```
{
    "type": "accept",
    "ack_seq": N
}
```

rejected:

```
{
    "type: "reject",
    "ack_seq": N,
    "reason": [["xxx"]]
}
```

or IGNORE

relayed:

```
{
    "type": "event",
    "event": "kick",
    "data": {
        "id_": P
    }
    "seq": M
}
```

## Rejoin

- path: CLIENT -> SERVER -> Other CLIENTS
- when: CLIENT rejoins

sent by CLIENT:

```
{
    "type: "join",
    "id_": P,
    "token": Q,
    "username": "xxx",
    "room_id_": R
}
```

> `room_id_` should not be zero

accepted & rejected & relayed:

same as Join

## Operate

- path: CLIENT -> SERVER -> Other CLIENTS
- when: CLIENT decides to operate or finish operating

sent by CLIENT:

```
{
    "type": "operate",
    "id_": P,
    "token": Q,
    "op": {x},
    "op_state": "declare" | "commit",
    "seq": N
}
```

accepted:

```
{
    "type": "accept",
    "ack_seq": N
}
```

rejected:

> note: every operation SHOULD be declared before it is committed, otherwise it SHOULD be rejected by server

```
{
    "type": "reject",
    "ack_seq": N,
    "reason": [["xxx"]]
}
```

or IGNORE

relayed:

```
{
    "type": "event",
    "event": "operate",
    "data": {
        "id_": P,
        "op": {x},
        "op_state": "declare" | "commit"
    },
    seq: M
}
```

### Structure of `"op"` field

```
{
    "type": "xxx",
    "component_id_": P,
    "changed": [[{x}]]
}
```

| op     | type       | component_id_                   | changed                                         |
| ------ | ---------- | ------------------------------- | ----------------------------------------------- |
| add    | `"add"`    | `id_` of the changed component  | content of the component                        |
| remove | `"remove"` | `id_`of the removed component   | `null`                                          |
| modify | `"modify"` | `id_` of the modified component | content of the component **after** modification |

### Possible reasons for rejection

| reason         |                                           |
| -------------- | ----------------------------------------- |
| `"occupied"`   | the component is changing by another peer |
| `"invalid_id"` | the `component_id` is invalid             |
| `null`         | others                                    |

## Message

TODO

## Accept

- path: SERVER -> a certain CLIENT
- when: accept a request

sent by SERVER:

```
{
    "type": "accept",
    "ack_seq": N,
    "data": [[{x}]]
}
```

## Reject

- path: SERVER -> a certain CLIENT
- when: reject a request explicitly

sent by SERVER:

```
{
    "type": "reject",
    "ack_seq": N,
    "reason": [["xxx"]]
}
```

## Event

- path: SERVER -> a set of CLIENTS | all CLIENTS
- when: something happens on SERVER | relay some requests

sent by SERVER:

```
{
    "type": "event",
    "event": "xxx",
    "seq": M,
    "data": [[{x}]]
}
```
