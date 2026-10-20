// A raylib-zig port of https://github.com/raysan5/raylib/blob/master/examples/core/core_3d_camera_fps.c

const rl = @import("raylib");
const math = @import("std").math;

//----------------------------------------------------------------------------------
// Defines and Macros
//----------------------------------------------------------------------------------
// Movement constants
const gravity = 32.0;
const max_speed = 20.0;
const crouch_speed = 5.0;
const jump_force = 12.0;
const max_accel = 150.0;
// Grounded drag
const friction = 0.86;
// Increasing air drag, increases strafing speed
const air_drag = 0.98;
// Responsiveness for turning movement direction to looked direction
const control = 15.0;
const crouch_height = 0.0;
const stand_height = 1.0;
const bottom_height = 0.5;

//----------------------------------------------------------------------------------
// Types and Structures Definition
//----------------------------------------------------------------------------------
// Body structure
const Body = struct {
    position: rl.Vector3,
    velocity: rl.Vector3,
    dir: rl.Vector3,
    is_grounded: bool,
};

//----------------------------------------------------------------------------------
// Global Variables Definition
//----------------------------------------------------------------------------------
const sensitivity = rl.Vector2.init(0.001, 0.001);

//------------------------------------------------------------------------------------
// Program main entry point
//------------------------------------------------------------------------------------
pub fn main() anyerror!void {
    // Initialization
    //--------------------------------------------------------------------------------------
    const screenWidth = 800;
    const screenHeight = 450;

    rl.initWindow(screenWidth, screenHeight, "raylib [core] example - 3d camera fps");
    defer rl.closeWindow();

    var look_rotation = rl.Vector2.init(0, 0);
    var lean = rl.Vector2.init(0, 0);
    var head_timer: f32 = 0.0;
    var walk_lerp: f32 = 0.0;
    var head_lerp: f32 = stand_height;
    var player = Body{ .position = rl.Vector3.zero(), .velocity = rl.Vector3.zero(), .is_grounded = true, .dir = rl.Vector3.zero() };

    // Initialize camera variables
    // NOTE: UpdateCameraFPS() takes care of the rest
    var camera = rl.Camera3D{
        .position = .init(0, 0, 0),
        .target = .init(0, 0, 0),
        .up = .init(0, 1, 0),
        .fovy = 60.0,
        .projection = .perspective,
    };
    camera.position = rl.Vector3.init(
        player.position.x,
        player.position.y + (bottom_height + head_lerp),
        player.position.z,
    );

    updateCameraFPS(&camera, &look_rotation, lean, head_timer, walk_lerp); // Update camera parameters

    rl.disableCursor(); // Limit cursor to relative movement inside the window

    rl.setTargetFPS(60); // Set our game to run at 60 frames-per-second
    //--------------------------------------------------------------------------------------

    // Main game loop
    while (!rl.windowShouldClose()) // Detect window close button or ESC key
    {
        // Update
        //----------------------------------------------------------------------------------
        const mouse_delta = rl.getMouseDelta();
        look_rotation.x -= mouse_delta.x * sensitivity.x;
        look_rotation.y += mouse_delta.y * sensitivity.y;

        const sideway = (@as(i8, (if (rl.isKeyDown(.d)) 1 else 0)) - @as(i8, (if (rl.isKeyDown(.a)) 1 else 0)));
        const forward = (@as(i8, (if (rl.isKeyDown(.w)) 1 else 0)) - @as(i8, (if (rl.isKeyDown(.s)) 1 else 0)));
        const crouching = rl.isKeyDown(.left_control);
        updateBody(&player, look_rotation.x, sideway, forward, rl.isKeyPressed(.space), crouching);

        const delta = rl.getFrameTime();
        head_lerp = math.lerp(head_lerp, @as(f32, if (crouching) crouch_height else stand_height), 20.0 * delta);
        camera.position = rl.Vector3.init(
            player.position.x,
            player.position.y + (bottom_height + head_lerp),
            player.position.z,
        );

        if (player.is_grounded and ((forward != 0) or (sideway != 0))) {
            head_timer += delta * 3.0;
            walk_lerp = math.lerp(walk_lerp, 1.0, 10.0 * delta);
            camera.fovy = math.lerp(camera.fovy, 55.0, 5.0 * delta);
        } else {
            walk_lerp = math.lerp(walk_lerp, 0.0, 10.0 * delta);
            camera.fovy = math.lerp(camera.fovy, 60.0, 5.0 * delta);
        }

        lean.x = math.lerp(lean.x, @as(f32, @floatFromInt(sideway)) * 0.02, 10.0 * delta);
        lean.y = math.lerp(lean.y, @as(f32, @floatFromInt(forward)) * 0.015, 10.0 * delta);

        updateCameraFPS(&camera, &look_rotation, lean, head_timer, walk_lerp); // Update camera parameters
        //----------------------------------------------------------------------------------

        // Draw
        //----------------------------------------------------------------------------------
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(.white);

        {
            camera.begin();
            defer camera.end();

            const floor_extent = 25;
            const tile_size = 5.0;
            const tile_color1 = rl.Color.init(150, 200, 200, 255);

            // Floor tiles
            for (0..floor_extent * 2) |y| {
                for (0..floor_extent * 2) |x| {
                    if ((y & 1) != 0 and (x & 1) != 0) {
                        rl.drawPlane(rl.Vector3.init(@as(f32, @floatFromInt(@as(isize, @intCast(x)) - floor_extent)) * tile_size, 0.0, @as(f32, @floatFromInt(@as(isize, @intCast(y)) - floor_extent)) * tile_size), rl.Vector2.init(tile_size, tile_size), tile_color1);
                    } else if ((y & 1) == 0 and (x & 1) == 0) {
                        rl.drawPlane(rl.Vector3.init(@as(f32, @floatFromInt(@as(isize, @intCast(x)) - floor_extent)) * tile_size, 0.0, @as(f32, @floatFromInt(@as(isize, @intCast(y)) - floor_extent)) * tile_size), rl.Vector2.init(tile_size, tile_size), .light_gray);
                    }
                }
            }

            const tower_size = rl.Vector3.init(16.0, 32.0, 16.0);
            const tower_color = rl.Color.init(150, 200, 200, 255);

            var tower_pos = rl.Vector3.init(16.0, 16.0, 16.0);
            rl.drawCubeV(tower_pos, tower_size, tower_color);
            rl.drawCubeWiresV(tower_pos, tower_size, .dark_blue);

            tower_pos.x *= -1;
            rl.drawCubeV(tower_pos, tower_size, tower_color);
            rl.drawCubeWiresV(tower_pos, tower_size, .dark_blue);

            tower_pos.z *= -1;
            rl.drawCubeV(tower_pos, tower_size, tower_color);
            rl.drawCubeWiresV(tower_pos, tower_size, .dark_blue);

            tower_pos.x *= -1;
            rl.drawCubeV(tower_pos, tower_size, tower_color);
            rl.drawCubeWiresV(tower_pos, tower_size, .dark_blue);

            // Red sun
            rl.drawSphere(rl.Vector3.init(300.0, 300.0, 0.0), 100.0, rl.Color.init(255, 0, 0, 255));
        }

        // Draw info box
        rl.drawRectangle(5, 5, 330, 75, .fade(.sky_blue, 0.5));
        rl.drawRectangleLines(5, 5, 330, 75, .blue);

        rl.drawText("Camera controls:", 15, 15, 10, .black);
        rl.drawText("- Move keys: W, A, S, D, Space, Left-Ctrl", 15, 30, 10, .black);
        rl.drawText("- Look around: arrow keys or mouse", 15, 45, 10, .black);
        rl.drawText(rl.textFormat("- Velocity Len: (%06.3f)", .{rl.Vector2.init(player.velocity.x, player.velocity.z).length()}), 15, 60, 10, .black);
        //----------------------------------------------------------------------------------
    }
}

//----------------------------------------------------------------------------------
// Module Functions Definition
//----------------------------------------------------------------------------------
// Update body considering current world state
fn updateBody(body: *Body, rot: f32, side: i8, forward: i8, jump_pressed: bool, crouch_hold: bool) void {
    var input = rl.Vector2.init(side, -forward);

    // Slow down diagonal movement
    if ((side != 0) and (forward != 0)) input = input.normalize();

    const delta = rl.getFrameTime();

    if (!body.is_grounded) body.velocity.y -= gravity * delta;

    if (body.is_grounded and jump_pressed) {
        body.velocity.y = jump_force;
        body.is_grounded = false;

        // Sound can be played at this moment
        //rl.setSoundPitch(fx_jump, 1.0 + (rl.getRandomValue(-100, 100)*0.001));
        //rl.playSound(fx_jump);
    }

    const front = rl.Vector3.init(math.sin(rot), 0, math.cos(rot));
    const right = rl.Vector3.init(math.cos(-rot), 0, math.sin(-rot));

    const desired_dir = rl.Vector3.init(input.x * right.x + input.y * front.x, 0.0, input.x * right.z + input.y * front.z);
    body.dir = body.dir.lerp(desired_dir, control * delta);

    const decel: f32 = if (body.is_grounded) friction else air_drag;
    var hvel = rl.Vector3.init(body.velocity.x * decel, 0.0, body.velocity.z * decel);

    const hvel_length = hvel.length(); // Magnitude
    if (hvel_length < (max_speed * 0.01)) hvel = rl.Vector3.init(0, 0, 0);

    // This is what creates strafing
    const speed = hvel.dotProduct(body.dir);

    // Whenever the amount of acceleration to add is clamped by the maximum acceleration constant,
    // a Player can make the speed faster by bringing the direction closer to horizontal velocity angle
    // More info here: https://youtu.be/v3zT3Z5apaM?t=165
    const max_curr_speed: f32 = if (crouch_hold) crouch_speed else max_speed;
    const accel = math.clamp((max_curr_speed - speed), 0.0, max_accel * delta);
    hvel.x += body.dir.x * accel;
    hvel.z += body.dir.z * accel;

    body.velocity.x = hvel.x;
    body.velocity.z = hvel.z;

    body.position.x += body.velocity.x * delta;
    body.position.y += body.velocity.y * delta;
    body.position.z += body.velocity.z * delta;

    // Fancy collision system against the floor
    if (body.position.y <= 0.0) {
        body.position.y = 0.0;
        body.velocity.y = 0.0;
        body.is_grounded = true; // Enable jumping
    }
}

// Update camera for FPS behaviour
fn updateCameraFPS(camera: *rl.Camera3D, look_rotation: *rl.Vector2, lean: rl.Vector2, head_timer: f32, walk_lerp: f32) void {
    const up = rl.Vector3.init(0.0, 1.0, 0.0);
    const targetOffset = rl.Vector3.init(0.0, 0.0, -1.0);

    // Left and right
    const yaw = targetOffset.rotateByAxisAngle(up, look_rotation.x);

    // Clamp view up
    var max_angle_up = up.angle(yaw);
    max_angle_up -= 0.001; // Avoid numerical errors
    if (-(look_rotation.y) > max_angle_up) {
        look_rotation.y = -max_angle_up;
    }

    // Clamp view down
    var max_angle_down = up.negate().angle(yaw);
    max_angle_down *= -1.0; // Downwards angle is negative
    max_angle_down += 0.001; // Avoid numerical errors
    if (-(look_rotation.y) < max_angle_down) {
        look_rotation.y = -max_angle_down;
    }

    // Up and down
    const right = yaw.crossProduct(up).normalize();

    // Rotate view vector around right axis
    var pitch_angle = -look_rotation.y - lean.y;
    pitch_angle = math.clamp(pitch_angle, -math.pi / 2.0 + 0.0001, math.pi / 2.0 - 0.0001); // Clamp angle so it doesn't go past straight up or straight down
    const pitch = yaw.rotateByAxisAngle(right, pitch_angle);

    // Head animation
    // Rotate up direction around forward axis
    const head_sin = math.sin(head_timer * math.pi);
    const head_cos = math.cos(head_timer * math.pi);
    const step_rotation = 0.01;
    camera.up = up.rotateByAxisAngle(pitch, head_sin * step_rotation + lean.x);

    // Camera BOB
    const bob_side = 0.1;
    const bob_up = 0.15;
    var bobbing = right.scale(head_sin * bob_side);
    bobbing.y = @abs(head_cos * bob_up);

    camera.position = camera.position.add(bobbing.scale(walk_lerp));
    camera.target = camera.position.add(pitch);
}
