package main

import "core:fmt"
import "core:mem"
import "core:strings"
import "core:os"
import rl "vendor:raylib"

main :: proc() {
	// initialize top level allocator
	main_arena: mem.Dynamic_Arena
	mem.dynamic_arena_init(&main_arena)
	defer mem.dynamic_arena_destroy(&main_arena)
	main_alloc := mem.dynamic_arena_allocator(&main_arena)

	// Get home envirment and attach default Music location (for now this is hardcoded)
	home := os.get_env("HOME", main_alloc)
	lib_path := fmt.aprintf("%s/Music", home, allocator = main_alloc)

	// Init the library at our ~/Music path
	lib_ok := init_library(lib_path)
	if !lib_ok {
		fmt.printf("Error loading library, closing now..")
		return
	}
	defer uninit_library()

	// Initialize raylib
    rl.InitWindow(800, 600, "Ohmin Audio")

	// Initialize the engine for playback
	if !engine_init() {
		fmt.eprintf("failed to initialize audio engine")
	}
	defer engine_close()

	for !rl.WindowShouldClose() {
        free_all(context.temp_allocator)
		rl.BeginDrawing()

		rl.ClearBackground(rl.WHITE)
		rl.DrawText(rl.TextFormat("loaded: %d tracks", len(library)), 10, 60, 20, rl.BLACK)

        // position text: "1:23 / 4:05"
        ctime := rl.TextFormat("%d:%02d / %d:%02d",
                                int(track_pos) / 60, int(track_pos) % 60,
                                int(track_len) / 60, int(track_len) % 60)

        rl.DrawText(ctime, 10, 570, 20, rl.BLACK)

        // progress bar, only once length is known (track_len > 0)
        if len_known {
            bar_w := f32(rl.GetScreenWidth() - 20) * (track_pos / track_len)
            rl.DrawRectangle(10, 590, i32(bar_w), 8, rl.BLACK)
        }

		rl.EndDrawing()

        key := rl.GetKeyPressed()
        #partial switch key {
            case .SPACE: play_pause()
            case .L: play_next()
            case .H: play_previous()
            case .EQUAL: toggle_autoplay()
            case:
                //Empty
            }

        handle_autoplay()
	}

	rl.CloseWindow()
}
