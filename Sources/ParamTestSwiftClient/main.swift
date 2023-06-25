import ParamTestSwift

class P {
    @ParameterizedTest([
        1,
        2,
        3,
    ])
    func f(value: Int) {
        print(value)
    }
    
    @ParameterizedTest([
        (1, 2, 3),
        (1, 3, 3),
    ])
    func assertWithTuple(a: Int, b: Int, c: Int) {
        assert(a + b == c)
    }
}

let p = P()
p.testF_0()
p.testF_1()
p.testF_2()
p.testAssertWithTuple_0()
p.testAssertWithTuple_1()
