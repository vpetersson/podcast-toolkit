# Podcast Toolkit

Here's a collection of tools/scripts that I've written to manage [my podcast](https://vpetersson.com/podcast/).

* [Podcast RSS Generator](https://github.com/vpetersson/podcast-rss-generator): A podcast RSS feed generator that lives entirely in GitHub, where the files are hosted on an S3 compatible storage.
* [Shorts Whisperer](https://github.com/vpetersson/shorts-whisperer): A tool that generates a title/description for a YouTube Short video (extracted from the full podcast).
* `reencode.sh`: I render the podcast into h264 output, since this is what many platforms (such as Spotify) are limited to. However, for the RSS feed, it's better to use h265 encoding due to better compression. This bash script just calls on `ffmpeg` to take the h264 input and spit out both an mp3 and an h265 file.
  * Note this script assumes that the original file(s) live in the `h264` folder, and it will create new folders called `h265` and `mp3` for the new files.
  * This script is idempotent.
