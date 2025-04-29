# CUDAMandelZoom
A simple, pure, copy-paste-run c++ cuda program which generates frames which you can use to create an mp4 video of a mandelbrot zoom.

You can manually edit the desired resulution in the code by modifying the WIDTH and HEIGHT parameters.
You can mannually set the desired amount of frames to generate by editing the FRAMES paramater.
You can manually set the zoom size bu editing the INITIAL_ZOOM_FACTOR paramater.
You can manually set the output folder in the int main() function.

The program generates raw, uncompressed ppm frames. If you are doing a 1080p video, each frame will have a size of 6mb. So if you want a 90hz 1080p video, the total frame data equals roughly 55gb. I know this isnt optimal, but I am not that experienced with using external DLL libraries or any of that visual depency stuff. You could use stuff like libpng16 to greatly reduce the total frame data size, but I dont really knwo how to do that. 

You can make a video by downloading the ffmpeg binaries from here: 

https://www.gyan.dev/ffmpeg/builds/

Then download the ffmpeg-git-full.7z file. After exstracting the data, you can use it as follows, from the CMD command line:

C:\users\John\Desktop\rendered-frames> [path_to_ffmpeg_binary] -framerate 90 -i frame%04d.ppm -c:v libx264 -preset fast -crf 30 zoom.mp4

The frame%04d means that it will use all the .ppm image files whose names are formatted like "frame0001" "frame0002" "frame0003" etc.
If you want to generate more than 9999 frames, just modify this part of the code: 

sprintf(filename, "C:\\users\\omere\\desktop\\img\\frame%04d.ppm", frame);

You can change the frame%04d to something like frame%06d. This can generate a total of 999999 frames. On my RTX 4060 8gb gpu, it can generate a decent amount of 1080p frames per second, although this depends heavily on the amount of iterations per frame. If you use 500 iterations, it will be done in an instant almost, but if you use something like 2500 or 5000, performance gets dragged into the negative direction, so you can experiment with that.

Here is an example of what it can generate, on my own youtube channel: https://www.youtube.com/watch?v=pzFzR4Jzd3M

