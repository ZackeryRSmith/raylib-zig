const std = @import("std");
const rl = @import("raylib");

const GamepadBrand = enum {
    xbox,
    playstation,
    generic,
};

const screen_width = 800;
const screen_height = 450;

// Set axis deadzones
const left_stick_deadzone_x = 0.1;
const left_stick_deadzone_y = 0.1;
const right_stick_deadzone_x = 0.1;
const right_stick_deadzone_y = 0.1;
const left_trigger_deadzone = -0.9;
const right_trigger_deadzone = -0.9;

pub fn main() !void {
    rl.setConfigFlags(.{ .msaa_4x_hint = true });

    rl.initWindow(screen_width, screen_height, "hi");
    defer rl.closeWindow();

    const tex_ps3_pad = try rl.loadTexture("resources/ps3.png");
    defer rl.unloadTexture(tex_ps3_pad);
    const tex_xbox_pad = try rl.loadTexture("resources/xbox.png");
    defer rl.unloadTexture(tex_xbox_pad);

    rl.setTargetFPS(60);

    var gamepad: i32 = 0;

    while (!rl.windowShouldClose()) {
        // Update
        // ...

        // Draw
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(.ray_white);

        if (rl.isKeyPressed(.left)) gamepad = @max(0, gamepad - 1);
        if (rl.isKeyPressed(.right)) gamepad +|= 1;

        if (rl.isGamepadAvailable(gamepad)) {
            rl.drawText(
                rl.textFormat("GP%d: %s", .{ gamepad, rl.getGamepadName(gamepad).ptr }),
                10,
                10,
                10,
                .black,
            );

            // Get axis values
            var left_stick_x = rl.getGamepadAxisMovement(gamepad, .left_x);
            var left_stick_y = rl.getGamepadAxisMovement(gamepad, .left_y);
            var right_stick_x = rl.getGamepadAxisMovement(gamepad, .right_x);
            var right_stick_y = rl.getGamepadAxisMovement(gamepad, .right_y);
            var left_trigger = rl.getGamepadAxisMovement(gamepad, .left_trigger);
            var right_trigger = rl.getGamepadAxisMovement(gamepad, .right_trigger);

            // Calculate deadzones
            if (@abs(left_stick_x) < left_stick_deadzone_x) left_stick_x = 0;
            if (@abs(left_stick_y) < left_stick_deadzone_y) left_stick_y = 0;
            if (@abs(right_stick_x) < right_stick_deadzone_x) right_stick_x = 0;
            if (@abs(right_stick_y) < right_stick_deadzone_y) right_stick_y = 0;
            if (@abs(left_trigger) < left_trigger_deadzone) left_trigger = -1;
            if (@abs(right_trigger) < right_trigger_deadzone) right_trigger = -1;

            switch (getBrand(gamepad)) {
                .xbox => {
                    rl.drawTexture(tex_xbox_pad, 0, 0, .dark_gray);

                    // Draw buttons: xbox home
                    if (rl.isGamepadButtonDown(gamepad, .middle)) rl.drawCircle(394, 89, 19, .red);

                    // Draw buttons: basic
                    if (rl.isGamepadButtonDown(gamepad, .middle_right)) rl.drawCircle(436, 150, 9, .red);
                    if (rl.isGamepadButtonDown(gamepad, .middle_left)) rl.drawCircle(352, 150, 9, .red);
                    if (rl.isGamepadButtonDown(gamepad, .right_face_left)) rl.drawCircle(501, 151, 15, .blue);
                    if (rl.isGamepadButtonDown(gamepad, .right_face_down)) rl.drawCircle(536, 187, 15, .lime);
                    if (rl.isGamepadButtonDown(gamepad, .right_face_right)) rl.drawCircle(572, 151, 15, .maroon);
                    if (rl.isGamepadButtonDown(gamepad, .right_face_up)) rl.drawCircle(536, 115, 15, .gold);

                    // Draw buttons: d-pad
                    rl.drawRectangle(317, 202, 19, 71, .black);
                    rl.drawRectangle(293, 228, 69, 19, .black);
                    if (rl.isGamepadButtonDown(gamepad, .left_face_up)) rl.drawRectangle(317, 202, 19, 26, .red);
                    if (rl.isGamepadButtonDown(gamepad, .left_face_down)) rl.drawRectangle(317, 202 + 45, 19, 26, .red);
                    if (rl.isGamepadButtonDown(gamepad, .left_face_left)) rl.drawRectangle(292, 228, 25, 19, .red);
                    if (rl.isGamepadButtonDown(gamepad, .left_face_right)) rl.drawRectangle(292 + 44, 228, 26, 19, .red);

                    // Draw buttons: left-right back
                    if (rl.isGamepadButtonDown(gamepad, .left_trigger_1)) rl.drawCircle(259, 61, 20, .red);
                    if (rl.isGamepadButtonDown(gamepad, .right_trigger_1)) rl.drawCircle(536, 61, 20, .red);

                    // rl.draw axis: left joystick
                    var left_gamepad_color: rl.Color = .black;
                    if (rl.isGamepadButtonDown(gamepad, .left_thumb)) left_gamepad_color = .red;
                    rl.drawCircle(259, 152, 39, .black);
                    rl.drawCircle(259, 152, 34, .light_gray);
                    rl.drawCircle(
                        259 + @as(i32, @intFromFloat(left_stick_x*20)),
                        152 + @as(i32, @intFromFloat(left_stick_y*20)),
                        25,
                        left_gamepad_color,
                    );

                    // rl.draw axis: right joystick
                    var right_gamepad_color: rl.Color = .black;
                    if (rl.isGamepadButtonDown(gamepad, .right_thumb)) right_gamepad_color = .red;
                    rl.drawCircle(461, 237, 38, .black);
                    rl.drawCircle(461, 237, 33, .light_gray);
                    rl.drawCircle(
                        461 + @as(i32, @intFromFloat(right_stick_x*20)),
                        237 + @as(i32, @intFromFloat(right_stick_y*20)),
                        25,
                        right_gamepad_color,
                    );

                    // rl.draw axis: left-right triggers
                    rl.drawRectangle(170, 30, 15, 70, .gray);
                    rl.drawRectangle(604, 30, 15, 70, .gray);
                    rl.drawRectangle(170, 30, 15, @as(i32, @intFromFloat((1 + left_trigger)/2*70)), .red);
                    rl.drawRectangle(604, 30, 15, @as(i32, @intFromFloat((1 + right_trigger)/2*70)), .red);

                    //rl.drawText(TextFormat("Xbox axis LT: %02.02f", rl.getGamepadAxisMovement(gamepad, .left_trigger)), 10, 40, 10, .black);
                    //rl.drawText(TextFormat("Xbox axis RT: %02.02f", rl.getGamepadAxisMovement(gamepad, .right_trigger)), 10, 60, 10, .black);
                },
                .playstation => {
                    rl.drawTexture(tex_ps3_pad, 0, 0, .dark_gray);

                    // Draw buttons: ps
                    if (rl.isGamepadButtonDown(gamepad, .middle)) rl.drawCircle(396, 222, 13, .red);

                    // Draw buttons: basic
                    if (rl.isGamepadButtonDown(gamepad, .middle_left)) rl.drawRectangle(328, 170, 32, 13, .red);
                    if (rl.isGamepadButtonDown(gamepad, .middle_right)) {
                        rl.drawTriangle(rl.Vector2.init(436, 168), rl.Vector2.init(436, 185), rl.Vector2.init(464, 177), .red);
                    }
                    if (rl.isGamepadButtonDown(gamepad, .right_face_up)) rl.drawCircle(557, 144, 13, .lime);
                    if (rl.isGamepadButtonDown(gamepad, .right_face_right)) rl.drawCircle(586, 173, 13, .red);
                    if (rl.isGamepadButtonDown(gamepad, .right_face_down)) rl.drawCircle(557, 203, 13, .violet);
                    if (rl.isGamepadButtonDown(gamepad, .right_face_left)) rl.drawCircle(527, 173, 13, .pink);

                    // Draw buttons: d-pad
                    rl.drawRectangle(225, 132, 24, 84, .black);
                    rl.drawRectangle(195, 161, 84, 25, .black);
                    if (rl.isGamepadButtonDown(gamepad, .left_face_up)) rl.drawRectangle(225, 132, 24, 29, .red);
                    if (rl.isGamepadButtonDown(gamepad, .left_face_down)) rl.drawRectangle(225, 132 + 54, 24, 30, .red);
                    if (rl.isGamepadButtonDown(gamepad, .left_face_left)) rl.drawRectangle(195, 161, 30, 25, .red);
                    if (rl.isGamepadButtonDown(gamepad, .left_face_right)) rl.drawRectangle(195 + 54, 161, 30, 25, .red);

                    // Draw buttons: left-right back buttons
                    if (rl.isGamepadButtonDown(gamepad, .left_trigger_1)) rl.drawCircle(239, 82, 20, .red);
                    if (rl.isGamepadButtonDown(gamepad, .right_trigger_1)) rl.drawCircle(557, 82, 20, .red);

                    // Draw axis: left joystick
                    var left_gamepad_color: rl.Color = .black;
                    if (rl.isGamepadButtonDown(gamepad, .left_thumb)) left_gamepad_color = .red;
                    rl.drawCircle(319, 255, 35, .black);
                    rl.drawCircle(319, 255, 31, .light_gray);
                    rl.drawCircle(
                        319 + @as(i32, @intFromFloat(left_stick_x*20)),
                        255 + @as(i32, @intFromFloat(left_stick_y*20)),
                        25,
                        left_gamepad_color,
                    );

                    // Draw axis: right joystick
                    var right_gamepad_color: rl.Color = .black;
                    if (rl.isGamepadButtonDown(gamepad, .right_thumb)) right_gamepad_color = .red;
                    rl.drawCircle(475, 255, 35, .black);
                    rl.drawCircle(475, 255, 31, .light_gray);
                    rl.drawCircle(
                        475 + @as(i32, @intFromFloat(right_stick_x*20)),
                        255 + @as(i32, @intFromFloat(right_stick_y*20)),
                        25,
                        right_gamepad_color,
                    );

                    // Draw axis: left-right triggers
                    rl.drawRectangle(169, 48, 15, 70, .gray);
                    rl.drawRectangle(611, 48, 15, 70, .gray);
                    rl.drawRectangle(169, 48, 15, @as(i32, @intFromFloat((1 + left_trigger)/2*70)), .red);
                    rl.drawRectangle(611, 48, 15, @as(i32, @intFromFloat((1 + right_trigger)/2*70)), .red);
                },
                .generic => {
                    // Draw background: generic
                    rl.drawRectangleRounded(rl.Rectangle.init(175, 110, 460, 220), 0.3, 16, .dark_gray);

                    // Draw buttons: basic
                    rl.drawCircle(365, 170, 12, .ray_white);
                    rl.drawCircle(405, 170, 12, .ray_white);
                    rl.drawCircle(445, 170, 12, .ray_white);
                    rl.drawCircle(516, 191, 17, .ray_white);
                    rl.drawCircle(551, 227, 17, .ray_white);
                    rl.drawCircle(587, 191, 17, .ray_white);
                    rl.drawCircle(551, 155, 17, .ray_white);
                    if (rl.isGamepadButtonDown(gamepad, .middle_left)) rl.drawCircle(365, 170, 10, .red);
                    if (rl.isGamepadButtonDown(gamepad, .middle)) rl.drawCircle(405, 170, 10, .green);
                    if (rl.isGamepadButtonDown(gamepad, .middle_right)) rl.drawCircle(445, 170, 10, .blue);
                    if (rl.isGamepadButtonDown(gamepad, .right_face_left)) rl.drawCircle(516, 191, 15, .gold);
                    if (rl.isGamepadButtonDown(gamepad, .right_face_down)) rl.drawCircle(551, 227, 15, .blue);
                    if (rl.isGamepadButtonDown(gamepad, .right_face_right)) rl.drawCircle(587, 191, 15, .green);
                    if (rl.isGamepadButtonDown(gamepad, .right_face_up)) rl.drawCircle(551, 155, 15, .red);

                    // Draw buttons: d-pad
                    rl.drawRectangle(245, 145, 28, 88, .ray_white);
                    rl.drawRectangle(215, 174, 88, 29, .ray_white);
                    rl.drawRectangle(247, 147, 24, 84, .black);
                    rl.drawRectangle(217, 176, 84, 25, .black);
                    if (rl.isGamepadButtonDown(gamepad, .left_face_up)) rl.drawRectangle(247, 147, 24, 29, .red);
                    if (rl.isGamepadButtonDown(gamepad, .left_face_down)) rl.drawRectangle(247, 147 + 54, 24, 30, .red);
                    if (rl.isGamepadButtonDown(gamepad, .left_face_left)) rl.drawRectangle(217, 176, 30, 25, .red);
                    if (rl.isGamepadButtonDown(gamepad, .left_face_right)) rl.drawRectangle(217 + 54, 176, 30, 25, .red);

                    // Draw buttons: left-right back
                    rl.drawRectangleRounded(rl.Rectangle.init(215, 98, 100, 10), 0.5, 16, .dark_gray);
                    rl.drawRectangleRounded(rl.Rectangle.init(495, 98, 100, 10), 0.5, 16, .dark_gray);
                    if (rl.isGamepadButtonDown(gamepad, .left_trigger_1)) {
                        rl.drawRectangleRounded(rl.Rectangle.init(215, 98, 100, 10), 0.5, 16, .red);
                    }
                    if (rl.isGamepadButtonDown(gamepad, .right_trigger_1)) {
                        rl.drawRectangleRounded(rl.Rectangle.init(495, 98, 100, 10), 0.5, 16, .red);
                    }

                    // Draw axis: left joystick
                    var left_gamepad_color: rl.Color = .black;
                    if (rl.isGamepadButtonDown(gamepad, .left_thumb)) left_gamepad_color = .red;
                    rl.drawCircle(345, 260, 40, .black);
                    rl.drawCircle(345, 260, 35, .light_gray);
                    rl.drawCircle(
                        345 + @as(i32, @intFromFloat(left_stick_x*20)),
                        260 + @as(i32, @intFromFloat(left_stick_y*20)),
                        25,
                        left_gamepad_color,
                    );

                    // Draw axis: right joystick
                    var right_gamepad_color: rl.Color = .black;
                    if (rl.isGamepadButtonDown(gamepad, .right_thumb)) right_gamepad_color = .red;
                    rl.drawCircle(465, 260, 40, .black);
                    rl.drawCircle(465, 260, 35, .light_gray);
                    rl.drawCircle(
                        465 + @as(i32, @intFromFloat(right_stick_x*20)),
                        260 + @as(i32, @intFromFloat(right_stick_y*20)),
                        25,
                        right_gamepad_color,
                    );

                    // Draw axis: left-right triggers
                    rl.drawRectangle(151, 110, 15, 70, .gray);
                    rl.drawRectangle(644, 110, 15, 70, .gray);
                    rl.drawRectangle(151, 110, 15, @as(i32, @intFromFloat((1 + left_trigger)/2*70)), .red);
                    rl.drawRectangle(644, 110, 15, @as(i32, @intFromFloat((1 + right_trigger)/2*70)), .red);
                },
            }

            rl.drawText(
                rl.textFormat("DETECTED AXIS [%i]:", .{ rl.getGamepadAxisCount(gamepad) }),
                10,
                50,
                10,
                .maroon,
            );

            for (0..@intCast(rl.getGamepadAxisCount(gamepad))) |i| {
                const axis = @as(rl.GamepadAxis, @enumFromInt(i));
                const text = rl.textFormat("AXIS %i: %.02f", .{ i, rl.getGamepadAxisMovement(gamepad, axis) });
                rl.drawText(text, 20, 70 + 20 * @as(i32, @intCast(i)), 10, .dark_gray);
            }

            if (rl.getGamepadButtonPressed() != .unknown) {
                const text = rl.textFormat("DETECTED BUTTON: %i", .{ @intFromEnum(rl.getGamepadButtonPressed()) });
                rl.drawText(text, 10, 430, 10, .red);
            } else {
                rl.drawText("DETECTED BUTTON: NONE", 10, 430, 10, .gray);
            }
        } else {
            rl.drawText(rl.textFormat("GP%d: NOT DETECTED", .{ gamepad }), 10, 10, 10, .gray);
            rl.drawTexture(tex_xbox_pad, 0, 0, .light_gray);
        }
    }
}

// NOTE: Gamepad name ID depends on drivers and OS
fn getBrand(gamepad: i32) GamepadBrand {
    const name_lower = rl.textToLower(rl.getGamepadName(gamepad));
    if (
        std.mem.containsAtLeast(u8, name_lower, 1, "xbox")
        or std.mem.containsAtLeast(u8, name_lower, 1, "x-box")
    ) return .xbox;
    if (std.mem.containsAtLeast(u8, name_lower, 1, "playstation")) {
        return .playstation;
    }
    return .generic;
}
