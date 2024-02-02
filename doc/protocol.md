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

There are 9 basic types of packets:

1. Join: sent by client at first join
2. Quit: sent by client when quitting
3. Rejoin: sent by client to restore the last join
4. Operate: sent by client to do some operation
5. Message: sent by client to convey some messages
6. Accept: sent by server to acknowledge some request
7. Reject: sent by server to reject some request
8. Event: sent by server when something happens on server
9. Kick

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
    "action": "join",
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
    "action": "accept",
    "data": {
        "id_": P,
        "token": Q,
        "ack_seq": N,
        "game_state": {x},
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
    "action": "event",
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
    "action": "quit",
    "id_": P,
    "token": Q,
    "seq": N,
    "room_id_": R
}
```

accepted:

NO RESPONSE

rejected:

IGNORE

relayed:

```
{
    "action": "event",
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
{
    "action": "kick",
    "id_": P,
    "to_kick_id_": P',
    "token": Q,
    "seq": N,
    "room_id_": R
}
```

accepted:

```
{
    "action": "accept",
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
    "action": "event",
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

> note: Operation `remove` and `modify` SHOULD be declared before it is committed, otherwise it SHOULD be rejected by server
> 
> Operation `add` does NOT need to declare

sent by CLIENT:

```
{
    "action": "operate",
    "id_": P,
    "token": Q,
    "ops": [{Operation}],
    "op_state": "declare" | "commit",
    "seq": N,
    "room_id_": R
}
```

accepted:

```
{
    "action": "accept",
    "ack_seq": N,
    "data": [[ {OperationRelayedData} ]]
}
```

> note: `"data"` is `null` IF AND ONLY IF `"op_state"` is `"declare"` in the request

rejected:

```
{
    "action": "reject",
    "ack_seq": N,
    "reason": [["xxx"]]
}
```

> note: all operations in request will be rejected together even if their is only 1 invalid operation among them!

or IGNORE

relayed:

```
{
    "action": "event",
    "event": "operate",
    "data": {OperationRelayedData},
    "seq": M
}
```

### Operation and OperationRelayeData

Operation:

```
{
    action: "add" | "remove" | "modify",
    component_id_: P,
    changed = [[ {Component} ]]
}
```

OperationRelayedData:

```
{
    id_: P,
    ops: [{Opration}...],
    op_state = "declare" | "commit"
}
```

a.k.a.

```python
@dataclass_json
@dataclass(kw_only=True)
class Operation:
    action: str
    component_id_: int
    changed: Optional[dict]

@dataclass_json
@dataclass(kw_only=True)
class OperationRelayedData:
    id_: int
    ops: list[Operation]
    op_state: str
```

| action     | type       | component_ids                  | changed                                         |
| ------ | ---------- | ------------------------------- | ----------------------------------------------- |
| add    | `"add"`    | `0`  | list of contents of the component                        |
| remove | `"remove"` | list of `id_`of the removed component   | `null`                                          |
| modify | `"modify"` | list of `id_` of the modified component | list of contents of the component **after** modification |

### Possible reasons for rejection


| reason         |                                           |
| -------------- | ----------------------------------------- |
| `"occupied_by_others_or_invalid_component_id"` | the component is changing by another peer |
| `"not_declared_or_changed_is_none"`   | the operation has not been declared or `changed` is `null` |
| `null`         | others                                    |

## Message

TODO

## Accept

- path: SERVER -> a certain CLIENT
- when: accept a request

sent by SERVER:

```
{
    "action": "accept",
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
    "action": "reject",
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
    "action": "event",
    "event": "xxx",
    "seq": M,
    "data": [[{x}]]
}
```
