# file-converter

A simple app to convert between various Document, Image, PDF, Video and Audio file formats.

- Supports batch conversion of multiple files
- Drag N Drop functionality
- Works on almost any Linux distro
- Progress bar

These formats and their equivalents are supported:
1) PDF
   - Can be converted (page-by-page) to jpg, png, tiff (Uses pdftoppm).
   - Can also be converted to a jpg containing only the first page (Uses pdftoppm).
   - Can be converted to html , odg (Uses LibreOffice).
2) Documents: pdf docx xlsx pptx odt ods odp odg odf odb doc ppt rtf xls epub html slk csv txt xml mml .... etc.,
   - All formats and conversions supported by LibreOffice.
   - Uses LibreOffice
4) Images: jpg png gif tiff bmp heic ico webp
   - Any of these can be interconverted
   - Uses convert-im6.q16
5) Audio: mp3 ogg wav aiff aac flac voc
   - Any of these can be interconverted
   - Uses ffmpeg
6) Video: mp4 mkv webm 3gp avi dat flv m4v mov rm
   - Any of these can be interconverted
   - Uses ffmpeg

Download latest beta version at https://github.com/TimothySimon123/file-converter/releases/tag/beta-release

AppImage: https://github.com/TimothySimon123/file-converter/releases/download/beta-release/file-converter-0.2-beta-x86_64.AppImage

deb: https://github.com/TimothySimon123/file-converter/releases/download/beta-release/file-converter-0.2-beta.deb
