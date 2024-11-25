const std = @import("std");
const c = @cImport({
    @cInclude("SDL2/SDL.h");
});

const WIDTH: i32 = 1280;
const HEIGHT: i32 = 1280;
const PIXEL_GRID_COL: i32 = 160;
const PIXEL_GRID_ROW: i32 = 160;
const PIXEL_WIDTH: i32 = @divFloor(WIDTH, PIXEL_GRID_COL);
const PIXEL_HIGHT: i32 = @divFloor(HEIGHT, PIXEL_GRID_ROW);
const FPS: u16 = 60;

const INIT = 1;

const Cell = struct {
    rect: c.SDL_Rect,
    isAlive: bool,
};

const GameState = struct {
    // number of alive cells in the grid
    population: u32,
    // game generation.
    generation: u32,
    // cells in the generation
    cells: [PIXEL_GRID_ROW][PIXEL_GRID_COL]Cell,
};

pub fn main() !void {
    // initialize SDL
    if (c.SDL_Init(c.SDL_INIT_VIDEO) != 0) {
        c.SDL_Log("Unable to initialize SDL: %s", c.SDL_GetError());
        return error.SDLInitializationFailed;
    }
    defer c.SDL_Quit();

    // create a window
    const screen = c.SDL_CreateWindow(
        "My Game Window",
        c.SDL_WINDOWPOS_UNDEFINED,
        c.SDL_WINDOWPOS_UNDEFINED,
        WIDTH,
        HEIGHT,
        c.SDL_WINDOW_OPENGL,
    ) orelse {
        c.SDL_Log("Unable to create window: %s", c.SDL_GetError());
        return error.SDLInitializationFailed;
    };
    defer c.SDL_DestroyWindow(screen);

    // create a renderer
    const renderer = c.SDL_CreateRenderer(screen, -1, 0) orelse {
        c.SDL_Log("Unable to create renderer: %s", c.SDL_GetError());
        return error.SDLInitializationFailed;
    };
    defer c.SDL_DestroyRenderer(renderer);

    // initialize the game state
    var game_state = GameState{
        .population = 0,
        .generation = 0,
        .cells = switch (INIT) {
            1 => initializeReno(),
            2 => initializeSmallerOne(),
            3 => initializeSmallerTwo(),
            else => initializeGospherGliderGun(),
        },
    };
    var quit = false;

    // main game loop
    while (!quit) {
        var event: c.SDL_Event = undefined;
        _ = c.SDL_RenderClear(renderer);
        while (c.SDL_PollEvent(&event) != 0) {
            switch (event.type) {
                c.SDL_QUIT => {
                    quit = true;
                },
                else => {},
            }
        }

        paintGeneration(&game_state, renderer);

        // std.debug.print("Generation: {d}\n population: {d}\n", .{
        //     game_state.generation,
        //     game_state.population,
        // });
        // set background color
        _ = c.SDL_SetRenderDrawColor(renderer, 0x29, 0x2d, 0x3e, 0);
        c.SDL_RenderPresent(renderer);
        c.SDL_Delay(1000 / FPS);
    }
}

fn paintGeneration(game_state: *GameState, renderer: *c.SDL_Renderer) void {
    var cs = game_state.*.cells;
    var population: u32 = 0;
    for (cs, 0..) |_, ro| {
        for (cs[ro], 0..) |_, cl| {
            var current_cell_p = &game_state.cells[ro][cl];
            // determine if dead or alive
            const number_of_neighbours = countNeigbours(
                cs,
                @as(i32, @intCast(ro)),
                @as(i32, @intCast(cl)),
            );

            if (current_cell_p.isAlive) {
                _ = c.SDL_SetRenderDrawColor(renderer, 0x95, 0x9d, 0xcb, 0);
                _ = c.SDL_RenderFillRect(renderer, &cs[ro][cl].rect);
                _ = c.SDL_RenderDrawRect(renderer, &cs[ro][cl].rect);
                population += 1;
            }

            if (number_of_neighbours == 3 or (number_of_neighbours == 2 and current_cell_p.*.isAlive)) {
                // alive
                current_cell_p.isAlive = true;
            } else {
                // die
                current_cell_p.isAlive = false;
            }
        }
    }
    game_state.population = population;
    game_state.generation += 1;
}

fn countNeigbours(cells: [PIXEL_GRID_ROW][PIXEL_GRID_COL]Cell, row: i32, col: i32) u16 {
    var count: u16 = 0;
    var i: i32 = -1;

    while (i < 2) : (i += 1) {
        var j: i32 = -1;
        while (j < 2) : (j += 1) {
            if (row + i >= 0 and row + i < PIXEL_GRID_ROW and
                col + j >= 0 and col + j < PIXEL_GRID_COL and
                (i != 0 or j != 0))
            {
                const nr = @as(usize, @intCast(row + i));
                const nc = @as(usize, @intCast(col + j));
                if (cells[nr][nc].isAlive) {
                    count += 1;
                }
            }
        }
    }

    return count;
}

fn initializeBase() [PIXEL_GRID_ROW][PIXEL_GRID_COL]Cell {
    var cells: [PIXEL_GRID_ROW][PIXEL_GRID_COL]Cell = undefined;

    for (cells, 0..) |_, row| {
        for (cells, 0..) |_, col| {
            cells[row][col].rect = .{
                .x = @as(i32, @intCast(col)) * PIXEL_WIDTH,
                .y = @as(i32, @intCast(row)) * PIXEL_HIGHT,
                .w = PIXEL_WIDTH,
                .h = PIXEL_HIGHT,
            };
            cells[row][col].isAlive = false;
        }
    }
    return cells;
}

// initialize the game state with a seed
fn initializeReno() [PIXEL_GRID_ROW][PIXEL_GRID_COL]Cell {
    var cells = initializeBase();
    cells[79][79].isAlive = true;
    cells[80][78].isAlive = true;
    cells[80][79].isAlive = true;
    cells[81][79].isAlive = true;
    cells[81][80].isAlive = true;
    return cells;
}

fn initializeSmallerOne() [PIXEL_GRID_ROW][PIXEL_GRID_COL]Cell {
    var cells = initializeBase();
    cells[80][87].isAlive = true;

    cells[82][85].isAlive = true;
    cells[82][87].isAlive = true;
    cells[82][88].isAlive = true;

    cells[83][85].isAlive = true;
    cells[83][87].isAlive = true;

    cells[84][85].isAlive = true;

    cells[85][83].isAlive = true;

    cells[86][81].isAlive = true;
    cells[86][83].isAlive = true;
    return cells;
}

fn initializeSmallerTwo() [PIXEL_GRID_ROW][PIXEL_GRID_COL]Cell {
    var cells = initializeBase();
    cells[81][81].isAlive = true;
    cells[81][82].isAlive = true;
    cells[81][83].isAlive = true;
    cells[81][85].isAlive = true;

    cells[82][81].isAlive = true;

    cells[83][84].isAlive = true;
    cells[83][85].isAlive = true;

    cells[84][82].isAlive = true;
    cells[84][83].isAlive = true;
    cells[84][85].isAlive = true;

    cells[85][81].isAlive = true;
    cells[85][83].isAlive = true;
    cells[85][85].isAlive = true;

    return cells;
}

fn initializeGospherGliderGun() [PIXEL_GRID_ROW][PIXEL_GRID_COL]Cell {
    var cells = initializeBase();

    cells[1][25].isAlive = true;

    cells[2][23].isAlive = true;
    cells[2][25].isAlive = true;

    cells[3][13].isAlive = true;
    cells[3][14].isAlive = true;
    cells[3][21].isAlive = true;
    cells[3][22].isAlive = true;
    cells[3][35].isAlive = true;
    cells[3][36].isAlive = true;

    cells[4][12].isAlive = true;
    cells[4][16].isAlive = true;
    cells[4][21].isAlive = true;
    cells[4][22].isAlive = true;
    cells[4][35].isAlive = true;
    cells[4][36].isAlive = true;

    cells[5][1].isAlive = true;
    cells[5][2].isAlive = true;
    cells[5][11].isAlive = true;
    cells[5][17].isAlive = true;
    cells[5][21].isAlive = true;
    cells[5][22].isAlive = true;

    cells[6][1].isAlive = true;
    cells[6][2].isAlive = true;
    cells[6][11].isAlive = true;
    cells[6][15].isAlive = true;
    cells[6][17].isAlive = true;
    cells[6][18].isAlive = true;
    cells[6][23].isAlive = true;
    cells[6][25].isAlive = true;

    cells[7][11].isAlive = true;
    cells[7][17].isAlive = true;
    cells[7][25].isAlive = true;

    cells[8][12].isAlive = true;
    cells[8][16].isAlive = true;

    cells[9][13].isAlive = true;
    cells[9][14].isAlive = true;

    return cells;
}
