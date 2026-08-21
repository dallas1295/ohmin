package main


import "core:fmt"
import ma "vendor:miniaudio"

engine: ma.engine

engine_init :: proc() -> bool {
    res := ma.engine_init(nil, &engine)

    if res != .SUCCESS {
        fmt.eprintf("error initializing miniaudio engine")
        return false
    }

    return true
}


engine_close :: proc() {
    ma.engine_uninit(&engine)
}
