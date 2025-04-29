#include "cuda_runtime.h"
#include "device_launch_parameters.h"
#include <cstdio>
#include <cmath>
#include <cstdlib>

const int WIDTH = 3840;
const int HEIGHT = 2160;
const int MAX_ITER = 1000;
const int TOTAL_FRAMES = 900;  // Total number of frames
const double INITIAL_ZOOM_FACTOR = 0.9975;  // Initial zoom factor per frame

__global__ void mandelbrot_kernel(unsigned char* output, double center_x, double center_y, double scale, double real_min, double real_max, double imag_min, double imag_max)
{
    int x = blockIdx.x * blockDim.x + threadIdx.x;
    int y = blockIdx.y * blockDim.y + threadIdx.y;

    if (x >= WIDTH || y >= HEIGHT) return;

    double real = real_min + (real_max - real_min) * x / WIDTH;
    double imag = imag_min + (imag_max - imag_min) * y / HEIGHT;

    double c_re = real;
    double c_im = imag;
    int iter = 0;

    while (real * real + imag * imag <= 4.0 && iter < MAX_ITER)
    {
        double real_new = real * real - imag * imag + c_re;
        double imag_new = 2.0 * real * imag + c_im;
        real = real_new;
        imag = imag_new;
        iter++;
    }

    // Simplified coloring without smooth iteration
    unsigned char r = (unsigned char)(iter * 1) % 256;
    unsigned char g = (unsigned char)(iter * 2) % 256;
    unsigned char b = (unsigned char)(iter * 4) % 256;

    int idx = (y * WIDTH + x) * 3;

    output[idx + 0] = r;
    output[idx + 1] = g;
    output[idx + 2] = b;
}

void save_ppm(const char* filename, unsigned char* data)
{
    FILE* f = fopen(filename, "wb");
    if (!f) {
        printf("Failed to open file for writing: %s\n", filename);
        return;
    }
    fprintf(f, "P6\n%d %d\n255\n", WIDTH, HEIGHT);
    fwrite(data, 1, WIDTH * HEIGHT * 3, f);
    fclose(f);
}

int main()
{
    unsigned char* d_output, * h_output;
    size_t size = WIDTH * HEIGHT * 3 * sizeof(unsigned char);

    cudaMalloc(&d_output, size);
    h_output = (unsigned char*)malloc(size);

    dim3 block(32, 32);
    dim3 grid((WIDTH + block.x - 1) / block.x, (HEIGHT + block.y - 1) / block.y);

    // Starting view parameters
    double center_x = 0.0;  // Start from the center of the Mandelbrot set
    double center_y = 0.0;  // Start from the center of the Mandelbrot set
    double scale = 2.0;      // Large scale to show the entire Mandelbrot set

    // The target coordinates to zoom into
    double target_x = -0.10944534372538328;
    double target_y = -0.8948242213462949;

    printf("Starting zoom sequence...\n");

    // Zoom into the target coordinates over multiple frames
    for (int frame = 0; frame < TOTAL_FRAMES; ++frame)
    {
        printf("Rendering frame %d/%d...\n", frame + 1, TOTAL_FRAMES);

        // Calculate the scale and pan (zoom) towards the target point
        double zoom_factor = INITIAL_ZOOM_FACTOR;

        // Gradually zoom in towards the target
        center_x += (target_x - center_x) * zoom_factor; // Pan to target_x
        center_y += (target_y - center_y) * zoom_factor; // Pan to target_y
        scale *= zoom_factor; // Decrease the scale for zoom

        // Precompute constants for real_min, real_max, imag_min, imag_max
        double real_min = center_x - scale;
        double real_max = center_x + scale;
        double imag_min = center_y - scale * HEIGHT / WIDTH;
        double imag_max = center_y + scale * HEIGHT / WIDTH;

        // Launch kernel with the current zoom parameters
        mandelbrot_kernel << <grid, block >> > (d_output, center_x, center_y, scale, real_min, real_max, imag_min, imag_max);

        // Copy the result from device to host
        cudaMemcpy(h_output, d_output, size, cudaMemcpyDeviceToHost);

        // Save current frame to PPM file
        char filename[256];
        sprintf(filename, "C:\\users\\omere\\desktop\\img\\frame%04d.ppm", frame);
        save_ppm(filename, h_output);
    }

    cudaFree(d_output);
    free(h_output);

    printf("All frames rendered!\n");
    system("pause");
    return 0;
}
