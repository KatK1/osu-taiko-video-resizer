# osu-taiko-video-resizer
Linux/macOS scripts to resize videos made for use in osu!taiko mapping

to use:
make sure `resize.sh`, `deflate.sh`, and the `assets/` folder are all in the same folder, from there navigate to that folder in a terminal and run `./resize.sh <video_path>` or `./deflate.sh <desired_size> <optional_video_path>`
when either script is run, the folder `output/` is made in the folder you run the scripts from, with the output of `resize.sh` stored as `output/output.mp4` and the output of `deflate.sh` stored as `output/smaller.mp4`
