import random

class NumberPool:
    
    def __init__(self):
        self.pool: set[int] = set()

    def allocate(self, reference) -> int:
        return self._allocate(reference)

    def _allocate(self, reference) -> int:
        ok = False
        new_number = 0
        while not ok:
            new_number = (hash(reference) + random.randint(1, 100)) % 2**30
            if new_number not in self.pool and self.validate(new_number):
                ok = True
        return new_number
    
    def add(self, data):
        self._add(data)
    
    def _add(self, data):
        if not self.present(data) and self.validate(data):
            self.pool.add(data)

    def present(self, data) -> bool:
        return data in self.pool
    
    def validate(self, data) -> bool:
        return data != 0
    
    def free(self, number: int):
        self._free(number)
    
    def _free(self, number: int):
        self.pool.discard(number)
    
    def __contains__(self, data: int):
        return self.present(data)

if __name__ == "__main__":
    # test
    pool = NumberPool()
    def test():
        num = pool.allocate(12)
        print(num)
        print("valid: ", pool.validate(num), True)
        print("present: ", pool.present(num), False)
        pool.add(num)
        print("valid: ", pool.validate(num), True)
        print("present: ", pool.present(num), True)
        pool.free(num)
        print("valid: ", pool.validate(num), True)
        print("present: ", pool.present(num), False)
    test()
