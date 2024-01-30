from dataclasses import dataclass
from dataclasses_json import dataclass_json
from typing import Optional

@dataclass_json
@dataclass(kw_only=True)
class JoinMessage:
    action: str = "join"
    seq: int
    id_: int
    token: int
    username: str
    room_id_: int

@dataclass_json
@dataclass(kw_only=True)
class QuitMessage:
    action: str = "quit"
    id_: int
    token: int
    room_id_: int
    seq: int

@dataclass_json
@dataclass(kw_only=True)
class OperateMessage:
    action: str = "operate"
    op: Optional[dict]
    op_state: str
    room_id_: int
    seq: int

@dataclass_json
@dataclass(kw_only=True)
class AcceptMessage:
    action: str = "accept"
    data: Optional[dict]
    seq: int
    ack_seq: int

@dataclass_json
@dataclass(kw_only=True)
class RejectMessage:
    action: str = "reject"
    reason: Optional[str]
    seq: int
    ack_seq: int

@dataclass_json
@dataclass(kw_only=True)
class EventMessage:
    action: str = "event"
    event: str
    seq: int
    data: Optional[dict]