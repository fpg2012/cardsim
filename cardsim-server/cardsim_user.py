from dataclasses import dataclass
from typing import Union, Optional, Dict
import websockets
from utils import NumberPool

@dataclass
class CardsimUser:
    id_: int
    token: int
    username: str
    websocket: websockets.WebSocketServerProtocol
    seq: int

class CardsimUserPool:

    ERROR_OK = 0
    ERROR_INVALID_USERNAME = 1

    def __init__(self) -> None:
        self.users: Dict[CardsimUser] = dict()
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
        
    def __contains__(self, user: CardsimUser):
        return user in self.users.values
    
    def __iter__(self):
        for user in self.users.values():
            yield user