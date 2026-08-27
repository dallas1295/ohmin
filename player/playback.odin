package player

import "core:fmt"
import "core:strings"
import ma "vendor:miniaudio"

auto_play := true
playing_now: bool
curr_track: ma.sound
curr_idx := -1
track_pos: f32
track_len: f32
len_known := false
sound_loaded: bool
volume: f32 = 0.50

play_song :: proc() {
	// if the curr_idx is above or at zero we uninit the sound prior to loading a new curr_track
	if sound_loaded {
		sound_loaded = false
		ma.sound_uninit(&curr_track)
	}

	// if the curr_idx is less nothing is loaded and we need to advance to 0 to start playing
	if curr_idx < 0 {
		curr_idx = 0
	}

	// spath converts the path in library to a cstring
	spath := strings.clone_to_cstring(library[curr_idx].path)
	defer delete(spath)

	// init the sound from the path provided by library and console error if something goes wrong
	res := ma.sound_init_from_file(&engine, spath, {.STREAM, .ASYNC}, nil, nil, &curr_track)
	ma.sound_set_volume(&curr_track, volume)
	if res != .SUCCESS {
		fmt.eprintfln("error loading sound file %s: %v", spath, res)
		if curr_idx + 1 < len(library) {
			play_next()
		}
		return
	}

	sound_loaded = true
	len_known = false
	playing_now = true

	ma.sound_start(&curr_track)
}

// play_next checks if we are still within the bounds of library's length
// if not it returns; if ok, then it advances curr_idx
play_next :: proc() {
	if curr_idx + 1 >= len(library) do return
	if playing_now {
		curr_idx += 1
		play_song()
	} else {
		curr_idx += 1
	}

}

// play_previous checks if we are still within the bounds of library's length
// if not it returns; if ok, then it retreats curr_idx
play_previous :: proc() {
	if curr_idx - 1 < 0 do return
	if playing_now {
		curr_idx -= 1
		play_song()
	} else {
		curr_idx -= 1
	}
}

play_pause :: proc() {
	// if curr_idx is less then or equal to 0 we just play.
	if curr_idx < 0 {
		play_song()
		return
		// if the sound is ending we just go to the next song
	} else if curr_idx >= 0 && !sound_loaded {
		play_next()
		return
	}

	// if the sound is playing it'll stop if it's stopped it'll play
	if ma.sound_is_playing(&curr_track) {
		playing_now = false
		ma.sound_stop(&curr_track) // suspend sound
	} else {
		playing_now = true
		ma.sound_start(&curr_track) // resume from suspend point
	}
}

toggle_autoplay :: proc() {
	auto_play = !auto_play
}

// loop assitant to keep music playing
handle_autoplay :: proc() {
	if curr_idx < 0 || !sound_loaded do return

	ma.sound_get_cursor_in_seconds(&curr_track, &track_pos)
	if !len_known {
		if ma.sound_get_length_in_seconds(&curr_track, &track_len) == .SUCCESS {
			len_known = true
		}
	}

	if !auto_play do return

	if ma.sound_at_end(&curr_track) {
		play_next()
	}
}

volume_up :: proc() {
	if volume += 0.01; volume > 1.0 {
		volume = 1.0
	}

	ma.sound_set_volume(&curr_track, volume)
}


volume_down :: proc() {
	if volume -= 0.01; volume < 0.0 {
		volume = 0.0
	}
	ma.sound_set_volume(&curr_track, volume)
}
