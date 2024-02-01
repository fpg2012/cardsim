import websockets
import asyncio
import json
from typing import Optional, Union, Iterable
import random
import traceback
from cardsim_user import *
from cardsim_message import *
from cardsim_component import *


class CardsimServer:
    
    def __init__(self):
        self.user_pool: CardsimUserPool = CardsimUserPool()
        self.component_pool: CardsimComponentPool = CardsimComponentPool()
        self.seq: int = random.randint(0, 10000)

        self.user_pool_lock = asyncio.Lock() # lock for user_pool
        self.component_pool_lock = asyncio.Lock() # lock for component_id_pool
        self.seq_lock = asyncio.Lock() # lock for seq

    async def run(self):
        async with websockets.serve(self.on_connected, 'localhost', 8765):
            await asyncio.Future()

    async def on_connected(self, websocket: websockets.WebSocketServerProtocol):
        try:
            async for message in websocket:
                print('message', message)
                try:
                    request = json.loads(message)
                    if type(request) != dict:
                        raise json.JSONDecodeError
                    await self.dispatch(request, websocket)
                except json.JSONDecodeError:
                    print('ignore: ', json.JSONDecodeError, message)
                except Exception as e:
                    print('ignore: ')
                    traceback.print_exception(e)
        except websockets.ConnectionClosedError as e:
            print('connection closed: ', websocket.remote_address)
    
    async def dispatch(self, request: dict, websocket):
        '''
        dispatch a request to a handler according to its `action` field 
        '''
        match request['action']:
            case 'join':
                asyncio.create_task(self.handle_join(request, websocket))
            case 'operate':
                asyncio.create_task(self.handle_operate(request, websocket))
            case _:
                print('ignore: ', 'invalid action')
    
    async def send_to_single(self, user: CardsimUser, packet):
        '''
        send to a single user, do nothing if `packet` is `None`,
        seq += 1
        '''
        if packet is None:
            return
        print('sent_to_single', user.public_profile, packet)
        try:
            await user.websocket.send(packet)
            await self.increment_seq()
        except websockets.exceptions.ConnectionClosedError as e:
            print('---ignore---')
            traceback.print_exception(e)
            print('------')

    async def send_to_group(self, users: Iterable[CardsimUser], packet):
        '''
        send to a group of users, do nothing if `packet` is `None`,
        seq += 1
        '''
        if packet is None:
            return
        print('send_to_group', packet)
        
        for user in users:
            try:
                await user.websocket.send(packet)
                await self.increment_seq()
                print('done:', user.public_profile)
            except websockets.exceptions.ConnectionClosedError as e:
                print('fail:', user.public_profile)
    
    async def handle_join(self, request, websocket):
        '''
        handle JOIN packet
        '''
        packet: JoinMessage = JoinMessage.from_dict(request)
        async with self.user_pool_lock:
            user = self.user_pool.add_user(websocket=websocket, username=packet.username, seq=packet.seq)
        if type(user) == CardsimUser:
            response = AcceptMessage(
                action='accept', 
                seq=self.seq, 
                ack_seq=user.seq, 
                data={
                    'id_': user.id_,
                    'token': user.token,
                    'game_state': self.game_state,
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
            await asyncio.gather(
                self.send_to_single(user, response.to_json()), # send to the `user`
                self.send_to_group(
                    filter(lambda u: u.id_ != user.id_, self.user_pool),
                    relayed.to_json()
                ) # relay to all except `user`
            )
        else:
            response = RejectMessage(
                action='reject',
                seq=self.seq,
                ack_seq=packet.seq,
                reason='username_used'
            )
            await websocket.send(response.to_json())
        
    
    async def handle_operate(self, request, websocket):
        '''
        handle OPERATE packet
        '''
        packet: OperateMessage = OperateMessage.from_dict(request)
        auth = await self.is_authenticated(packet.id_, packet.token)
        if not auth:
            print('not auth')
            return
        match packet.op_state:
            case 'declare':
                await self.handle_operate_declare(packet, websocket)
            case 'commit':
                await self.handle_operate_commit(packet, websocket)
            case _:
                pass # error
    
    async def handle_operate_declare(self, packet: OperateMessage, websocket):
        '''
        grab components for action `remove` and `modify`,
        ignore action `add`
        '''

        # check if ok to proceed
        ok = True
        for op in packet.ops:
            match op.action:
                case 'add':
                    pass
                case 'remove' | 'modify':
                    ok = ok and not self.component_pool.is_occupied(op.component_id_)
                case _:
                    pass # error
        if not ok:
            # reject
            response = RejectMessage(
                action='reject',
                seq=self.seq,
                ack_seq=packet.seq,
                reason='occupied_by_others_or_invalid_component_id'
            )
            await self.send_to_single(self.user_pool[packet.id_], response.to_json())
            return
        
        # grab
        actions = []
        async with self.component_pool_lock:
            for op in packet.ops:
                match op.action:
                    case 'add':
                        actions.append(Operation(action='add', component_id_=op.component_id_, changed=None))
                    case 'remove' | 'modify':
                        self.component_pool.grab(op.component_id_, packet.id_)
                        actions.append(Operation(action='remove', component_id_=op.component_id_, changed=None))
                    case _:
                        pass # error
        response = AcceptMessage(data=None, seq=self.seq, ack_seq=packet.seq)
        relayed = EventMessage(event='operate', seq=self.seq, data=OperationRelayedData(
            id_=packet.id_,
            ops=actions,
            op_state='declare'
        ).to_dict())
        await asyncio.gather(
            self.send_to_single(self.user_pool[packet.id_], response.to_json()),
            self.send_to_group(
                filter(lambda u: u.id_ != packet.id_, self.user_pool),
                relayed.to_json()
            )
        )

    async def handle_operate_commit(self, packet: OperateMessage, websocket):
        '''
        commit component updates
        '''
        
        # check if ok to proceed
        ok = True
        for op in packet.ops:
            match op.action:
                case 'add':
                    ok = ok and op.changed is not None
                case 'remove':
                    ok = ok and self.component_pool.is_occupied_by(op.component_id_, packet.id_)
                case 'modify':
                    ok = ok and self.component_pool.is_occupied_by(op.component_id_, packet.id_) and op.changed is not None
                case _:
                    pass # error
        if not ok:
            # reject
            response = RejectMessage(
                action='reject',
                seq=self.seq,
                ack_seq=packet.seq,
                reason='not_declared_or_changed_is_none'
            )
            await self.send_to_single(self.user_pool[packet.id_], response.to_json())
            return

        actions = []
        async with self.component_pool_lock:
            for op in packet.ops:
                match op.action:
                    case 'add':
                        component_id_ = self.component_pool.add_component(op.changed)
                        op.component_id_ = component_id_
                        actions.append(op)
                    case 'remove':
                        self.component_pool.remove_component(op.component_id_)
                        actions.append(op)
                    case 'modify':
                        self.component_pool.update_component(op.component_id_, op.changed)
                        actions.append(op)
                    case _:
                        pass # error
        
        response = AcceptMessage(seq=self.seq, ack_seq=packet.seq, data=OperationRelayedData(id_=packet.id_, ops=actions, op_state='commit').to_dict())
        relayed = EventMessage(event='operate', seq=self.seq, data=OperationRelayedData(id_=packet.id_, ops=actions, op_state='commit').to_dict())
        await asyncio.gather(
            self.send_to_single(self.user_pool[packet.id_], response.to_json()),
            self.send_to_group(
                filter(lambda u: u.id_ != packet.id_, self.user_pool),
                relayed.to_json()
            )
        )
        
    async def is_authenticated(self, user_id_: int, token: int) -> bool:
        async with self.user_pool_lock:
            ok = self.user_pool.check_token(user_id_, token)
        return ok

    async def increment_seq(self):
        async with self.seq_lock:
            self.seq += 1
    
    def user_leave(self, user: CardsimUser):
        pass
    
    @property
    def game_state(self) -> dict:
        return {
            'online': [pp.to_dict() for pp in self.user_pool.public_profiles()],
            'components': [cpn for cpn in self.component_pool],
        }

if __name__ == '__main__':
    server = CardsimServer()
    asyncio.run(server.run())