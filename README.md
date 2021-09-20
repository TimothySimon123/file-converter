# file-converter

A simple app to convert between various file formats.

- Supports batch conversion of multiple files
- Drag N Drop functionality
- Works on almost any Linux distro
- Progress bar

These formats and their equivalents are supported:
1) PDF
   - Can be converted (page-by-page) to jpg, png, tiff
   - Can also be converted to a jpg containing only the first page
   - Uses pdftoppm
2) Images: jpg png tiff bmp heic
   - Any of these can be interconverted
   - Uses convert-im6.q16
3) Audio: aiff aiffc au amr-nb amr-wb cdda flac gsm mp3 ogg opus sln voc vox wav wv 8svx
   - Any of these can be interconverted
   - Uses sox
4) Video: 3g2 3gp asf avi m4v mkv mov mp4 nsv rm roq vob webm
   - Any of these can be interconverted
   - Uses ffmpeg

Download latest beta version at https://github.com/TimothySimon123/file-converter/releases/tag/beta-release

AppImage: https://github.com/TimothySimon123/file-converter/releases/download/beta-release/file-converter-0.2-beta-x86_64.AppImage

deb: https://github.com/TimothySimon123/file-converter/releases/download/beta-release/file-converter-0.2-beta.deb
