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

@dataclass
class CardsimUser:
    id_: int
    token: int
    username: str
    websocket: websockets.WebSocketServerProtocol
    seq: int
    online: bool = True

    @property
    def public_profile(self) -> CardsimUserPublicProfile:
        return CardsimUserPublicProfile(id_=self.id_, username=self.username)

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