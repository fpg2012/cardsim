from dataclasses import dataclass
from dataclasses_json import dataclass_json
from typing import Union, Optional, Iterable
import websockets
from utils import NumberPool

@dataclass_json
@dataclass
class CardsimUserPublicProfile:
    id_: int
    username: str
    ping: float

class CardsimUser:

    def __init__(self, id_: int, token: int, username: str, websocket: websockets.WebSocketServerProtocol, seq: int, online: bool = True, grabbed_components: set[int] = set()) -> None:
        self.id_: int = id_
        self.token: int = token
        self.username: str = username
        self.websocket: websockets.WebSocketServerProtocol = websocket
        self.seq: int = seq
        self.online: bool = online
        self.grabbed_components: set = grabbed_components

    @property
    def public_profile(self) -> CardsimUserPublicProfile:
        return CardsimUserPublicProfile(id_=self.id_, username=self.username, ping=self.ping)
    
    def grab(self, component_id_: int):
        self.grabbed_components.add(component_id_)
    
    def release(self, component_id_: int):
        self.grabbed_components.discard(component_id_)
    
    @property
    def ping(self) -> float:
        self.websocket.latency

class CardsimUserPool(Iterable):

    ERROR_OK = 0
    ERROR_INVALID_USERNAME = 1

    def __init__(self) -> None:
        self.users: dict[int, CardsimUser] = dict()
        self.usernames: set[str] = set()
        self.id_pool: NumberPool = NumberPool()
        self.token_pool: NumberPool = NumberPool()
    
    def validate_username(self, username: str) -> bool:
        username = username.strip()
        if len(username) > 50 or len(username) <= 1:
            return False
        return username not in self.usernames

    def check_token(self, id_: int, token: int) -> bool:
        return id_ in self.id_pool and self.users[id_].token == token

    def add_user(self, websocket: websockets.WebSocketServerProtocol, username: str, seq: int) -> Union[int, CardsimUser]:
        if not self.validate_username(username):
            return CardsimUserPool.ERROR_INVALID_USERNAME
        
        id_ = self.id_pool.allocate(username)
        token = self.token_pool.allocate(id_)

        new_user = CardsimUser(id_, token, username, websocket, seq)
        self.users[id_] = new_user

        self.id_pool.add(id_)
        self.token_pool.add(token)
        return new_user

    def remove_user(self, id_: int):
        if id_ in self.id_pool:
            token = self.users[id_].token
            username = self.users[id_].username
            self.usernames.discard(username)
            del self.users[id_]
            self.id_pool.free(id_)
            self.token_pool.free(token)
    
    def public_profiles(self):
        for user in self.users.values():
            yield user.public_profile
        
    def __contains__(self, user: CardsimUser):
        return user in self.users.values()
    
    def __iter__(self):
        for user in self.users.values():
            yield user
    
    def __getitem__(self, index: int) -> CardsimUser:
        return self.users[index]