import websockets
import asyncio
import json
from typing import Optional, Union, Iterable
from cardsim_user import *
from message import *
import random

class CardsimServer:
    
    def __init__(self):
        self.user_pool = CardsimUserPool()
        self.seq = random.randint(0, 10000)
        self.user_pool_lock = asyncio.Lock()
        self.seq_lock = asyncio.Lock()

    async def run(self):
        async with websockets.serve(self.on_connected, 'localhost', 8765):
            await asyncio.Future()

    async def on_connected(self, websocket):
        async for message in websocket:
            print(message)
            try:
                request = json.loads(message)
                await self.dispatch(request, websocket)
            except json.JSONDecodeError:
                print("ignore: ", json.JSONDecodeError, message)
            except Exception as e:
                print(type(e), e)
    
    async def dispatch(self, request, websocket):
        print("request: ", request)
        match request["action"]:
            case "join":
                packet: JoinMessage = JoinMessage.from_dict(request)
                async with self.user_pool_lock:
                    user = self.user_pool.add_user(websocket=websocket, username=packet.username, seq=packet.seq)
                if type(user) == CardsimUser:
                    response = AcceptMessage(
                        action='accept', 
                        seq=self.seq, 
                        ack_seq=user.seq, 
                        data={
                            "id_": user.id_,
                            "token": user.token,
                        }
                    )
                    relayed = EventMessage(
                        action='event',
                        event='join',
                        seq=self.seq,
                        data={
                            'id_': user.id_,
                            'username': user.username,
                        }
                    )
                else:
                    response = RejectMessage(
                        action='reject',
                        seq=self.seq,
                        ack_seq=user.seq,
                        reason="username_used"
                    )
                    relayed = None
                await self.send_to_single(user, response.to_json())
                if relayed is not None:
                    await self.send_to_group(
                        filter(lambda u: u.id_ != user.id_, self.user_pool),
                        relayed.to_json()
                    )
            case _:
                print("ignore: ", "invalid action")
    
    async def send_to_single(self, user: CardsimUser, packet):
        await user.websocket.send(packet)
        async with self.seq_lock:
            self.seq += 1

    async def send_to_group(self, users: Iterable[CardsimUser], packet):
        async with self.seq_lock:
            self.seq += 1

if __name__ == "__main__":
    server = CardsimServer()
    asyncio.run(server.run())