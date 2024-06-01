#include <iostream>
#include <cmath>
#include <vector>
#include <cstdlib>

#include <SDL2/SDL.h>

#include "Vtt_um_vga_game.h"
#include "verilated.h"

#define WINDOW_WIDTH  640
#define WINDOW_HEIGHT 480

int main(int argc, char **argv) {

	std::vector< uint8_t > framebuffer(WINDOW_WIDTH * WINDOW_HEIGHT * 4, 0);

	Verilated::commandArgs(argc, argv);

	Vtt_um_vga_game *top = new Vtt_um_vga_game;

	// Reset module
	top->clk = 0;
	top->eval();
	top->rst_n = 0;
	top->clk = 1;
	top->eval();
	top->rst_n = 1;

	SDL_Init(SDL_INIT_VIDEO);

	SDL_Window* window =
	    SDL_CreateWindow(
	        "Tiny Tapeout VGA Game",
	        SDL_WINDOWPOS_UNDEFINED,
	        SDL_WINDOWPOS_UNDEFINED,
	        WINDOW_WIDTH,
	        WINDOW_HEIGHT,
	        0
	    );

	SDL_Renderer* renderer =
	    SDL_CreateRenderer(
	        window,
	        -1,
	        SDL_RENDERER_ACCELERATED
	    );

	SDL_SetRenderDrawColor(renderer, 0, 0, 0, SDL_ALPHA_OPAQUE);
	SDL_RenderClear(renderer);

	SDL_Event e;

	SDL_Texture* texture =
	    SDL_CreateTexture(
	        renderer,
	        SDL_PIXELFORMAT_ARGB8888,
	        SDL_TEXTUREACCESS_STREAMING,
	        WINDOW_WIDTH,
	        WINDOW_HEIGHT
	    );

	bool quit = false;

	int hnum = 0;
	int vnum = 0;

	while (!quit) {

		while (SDL_PollEvent(&e) == 1) {
			if (e.type == SDL_QUIT) {
				quit = true;
			} else if (e.type == SDL_KEYDOWN) {
				switch (e.key.keysym.sym) {
				case SDLK_q:
					quit = true;
				default:
					break;
				}
			}
		}

		auto keystate = SDL_GetKeyboardState(NULL);

		top->rst_n = !keystate[SDL_SCANCODE_R];

		// simulate for 20000 clocks
		for (int i = 0; i < 20000; ++i) {
			auto keystate = SDL_GetKeyboardState(NULL);
			top->ui_in = keystate[SDL_SCANCODE_A] | (keystate[SDL_SCANCODE_D] << 1) | (keystate[SDL_SCANCODE_W] << 2) | (keystate[SDL_SCANCODE_S] << 3) ;

			top->clk = 0;
			top->eval();
			top->clk = 1;
			top->eval();

			uint8_t uo_out = top->uo_out;
			// uo_out = {hsync, b0, g0, r0, vsync, b1, g1, r1}:
			uint8_t hsync = (uo_out & 0b10000000) >> 7;
			uint8_t vsync = (uo_out & 0b00001000) >> 3;
			uint8_t pix_rr = ((uo_out & 0b00000001) << 1) | ((uo_out & 0b00010000) >> 4);
			uint8_t pix_gg = ((uo_out & 0b00000010) << 0) | ((uo_out & 0b00100000) >> 5);
			uint8_t pix_bb = ((uo_out & 0b00000100) >> 1) | ((uo_out & 0b01000000) >> 6);

			// h and v blank logic
			if ((0 == hsync) && (0 == vsync)) {
				hnum = -128;
				vnum = -28;
			}

			// active frame
			if ((hnum >= 0) && (hnum < 640) && (vnum >= 0) && (vnum < 480)) {
				framebuffer.at((vnum * WINDOW_WIDTH + hnum) * 4 + 0) = pix_bb << 6;
				framebuffer.at((vnum * WINDOW_WIDTH + hnum) * 4 + 1) = pix_gg << 6;
				framebuffer.at((vnum * WINDOW_WIDTH + hnum) * 4 + 2) = pix_rr << 6;
			}

			// keep track of encountered fields
			hnum++;
			if (hnum >= 640 + 24 + 40) {
				hnum = -128;
				vnum++;
			}

		}

		SDL_UpdateTexture(
		    texture,
		    NULL,
		    framebuffer.data(),
		    WINDOW_WIDTH * 4
		);

		SDL_RenderCopy(
		    renderer,
		    texture,
		    NULL,
		    NULL
		);

		SDL_RenderPresent(renderer);
	}

	top->final();
	delete top;

	SDL_DestroyRenderer(renderer);
	SDL_DestroyWindow(window);
	SDL_Quit();

	return EXIT_SUCCESS;
}