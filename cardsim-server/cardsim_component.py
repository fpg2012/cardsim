from typing import Union, Optional, Iterable
import websockets
from utils import NumberPool
import time

class CardsimComponentPool(Iterable):

    ERROR_OK = 0
    ERROR_INVALID_USERNAME = 1

    def __init__(self) -> None:
        self.components: dict[int, dict] = {}
        self.id_pool: NumberPool = NumberPool()
        self.occupied_by: dict[int, int] = {}

    def add_component(self, component: dict) -> int:
        '''
        add `component` and return its `id_`
        '''
        
        id_ = self.id_pool.allocate(time.time())

        new_component = component

        # never update the component_id_ inside component structure unless protocol or client behavior changed
        # clients rely on "old" component_id_ in the component structure to behave correctly
        # they will replace old component_id_ when server responded (event=>operate=>commit)
        #
        # new_component['component_id_'] = id_ 
        
        self.components[id_] = new_component

        self.id_pool.add(id_)
        return id_
    
    def remove_component(self, component_id_: int):
        '''
        remove the component, do nothing if `component_id_` is invalid
        '''
        self.release(component_id_)
        if component_id_ in self.id_pool:
            self.id_pool.free(component_id_)
            del self.components[component_id_]
    
    def update_component(self, component_id_: int, component: dict):
        '''
        update the component, do nothing if `component_id_` is invalid
        '''
        if component_id_ in self.id_pool:
            self.components[component_id_] = component

    
    def grab(self, component_id_: int, user_id_: int) -> bool:
        '''
        `user_id_` should be valid
        
        return `False` if the component did not exists or had been occupied
        '''
        if self.id_pool.present(component_id_) and component_id_ not in self.occupied_by.keys():
            self.occupied_by[component_id_] = user_id_
            return True
        return False
    
    def is_occupied(self, component_id_: int) -> bool:
        '''
        check if the component has been grabbed
        '''
        return self.id_pool.present(component_id_) and component_id_ in self.occupied_by.keys()

    def is_occupied_by(self, component_id_: int, user_id_: int) -> bool:
        '''
        check if the component has been grabbed by the user
        '''
        return self.id_pool.present(component_id_) and component_id_ in self.occupied_by.keys() and self.occupied_by[component_id_] == user_id_

    def release(self, component_id_: int):
        if self.id_pool.present(component_id_) and component_id_ in self.occupied_by.keys():
            del self.occupied_by[component_id_]
        
    def __contains__(self, component: dict):
        return component in self.components.values()
    
    def __iter__(self):
        for component in self.components.values():
            yield component
    
    def __getitem__(self, index: int) -> int:
        return self.components[index]