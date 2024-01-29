from dataclasses import dataclass
from dataclasses_json import dataclass_json
from typing import Optional

@dataclass_json
@dataclass(kw_only=True)
class CardsimMessage:
    action: str

    def validate(self):
        return True

@dataclass_json
@dataclass(kw_only=True)
class CardsimRequest(CardsimMessage):
    seq: int

@dataclass_json
@dataclass(kw_only=True)
class CardsimResponse(CardsimMessage):
    seq: int
    ack_seq: int

@dataclass_json
@dataclass(kw_only=True)
class CardsimAuthRequest(CardsimMessage):
    id_: int
    token: int

@dataclass_json
@dataclass(kw_only=True)
class CardsimAuthRoomRequest(CardsimAuthRequest):
    room_id_: int

@dataclass_json
@dataclass
class JoinMessage(CardsimAuthRoomRequest):
    action = "join"
    seq: int
    id_: int
    token: int
    username: str
    room_id_: int

@dataclass_json
@dataclass(kw_only=True)
class QuitMessage(CardsimAuthRoomRequest):
    action = "quit"

@dataclass_json
@dataclass(kw_only=True)
class OperateMessage(CardsimAuthRoomRequest):
    action = "operate"
    op: Optional[dict]
    op_state: str

@dataclass_json
@dataclass(kw_only=True)
class AcceptMessage(CardsimResponse):
    action = "accept"
    data: Optional[dict]
    seq: int
    ack_seq: int

@dataclass_json
@dataclass
class RejectMessage(CardsimResponse):
    action = "reject"
    reason: Optional[str]
    seq: int
    ack_seq: int

@dataclass_json
@dataclass
class EventMessage(CardsimMessage):
    action = "event"
    event: str
    seq: int
    data: Optional[dict]