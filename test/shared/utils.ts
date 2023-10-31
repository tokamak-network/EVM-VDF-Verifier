export const generatorList = [
    5, 6, 11, 14, 17, 18, 20, 24, 31, 43, 44, 45, 46, 50, 53, 56, 58, 65, 68, 72, 77, 78, 80, 93,
    94, 96, 97, 98, 99, 101, 103, 105, 107, 110, 111, 114, 115, 119, 124, 126, 127, 134, 135, 137,
    140, 142, 143, 150, 151, 153, 158, 162, 163, 166, 167, 170, 172, 174, 176, 178, 179, 180, 181,
    183, 184, 197, 199, 200, 205, 209, 212, 219, 221, 224, 227, 231, 232, 233, 234, 246, 253, 257,
    259, 260, 263, 266, 271, 272,
]

export const gGen = () => {
    const index = Math.floor(Math.random() * generatorList.length)
    return generatorList[index]
}

export const simpleVDF = (a: number, N: number, time: number) => {
    for (let i = 0; i < time; i++) {
        a = (a * a) % N
    }
    return a
}

//excludes max, includes min
export const getRandomInt = (min: number, max: number) => {
    return Math.floor(Math.random() * (max - min)) + min
}

export const randomNoRepeats = (array: number[]) => {
    let copy = array.slice(0)
    return function () {
        if (copy.length < 1) {
            copy = array.slice(0)
        }
        let index = Math.floor(Math.random() * copy.length)
        let item = copy[index]
        copy.splice(index, 1)
        return item
    }
}

export const powerMod = (a: number, b: bigint, n: number) => {
    let res = 1
    while (b > 0) {
        if (b & BigInt(1)) {
            res = (res * a) % n
        }
        a = (a * a) % n
        b >>= BigInt(1)
    }
    return res
}
