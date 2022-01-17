#import "GetRect";
Simp  :: #import "Simp";
Input :: #import "Input";

#import "Window_Creation";

#import "Basic";
#import "File";
#import "Math";
system :: #import "System";
jai_string :: #import "String";


main_window: Window_Type;
window_width  : s32 = 1024;
window_height : s32 = 768;

current_time: float64;
last\  _time: float64;


file :: "jinx.pdb";
data : string;

quit := false;
last_clicked := "";


main :: () {
    data = read_entire_file(file);

    #if OS == .WINDOWS {
        Windows :: #import "Windows";
        Windows.timeBeginPeriod(1);
    }

    main_window = create_window(window_width, window_height, "Jinx");
    #if OS == .WINDOWS {
        Windows.DragAcceptFiles(main_window, cast(Windows.BOOL) true);
    } else #if OS == .LINUX {
        X11 :: #import "X11";
        typelist := string.["url/url", "text/uri-list", "text/plain", "application/octet-stream"];
        X11.enable_drag_and_drop(main_window, typelist);
    }

    Simp.set_render_target(main_window);

    init_fonts();
    setup_theme();
    ui_init();


    while !quit {
        last_time = current_time;
        current_time = get_time();
        dt := cast(float)(current_time - last_time);
        Clamp(*dt, 0, 0.1);

        Input.update_window_events();

        for Input.get_window_resizes() {
            Simp.update_window(it.window);

            if it.window == main_window {
                window_width  = it.width;
                window_height = it.height;
            }
        }

        for event: Input.events_this_frame {
            if event.type == .QUIT then quit = true;

            getrect_handle_event(event);

            if event.type == {
              case .KEYBOARD;
                if event.key_pressed && event.key_code == .ESCAPE {
                    active_widget_deactivate_all();
                }
              case .DRAG_AND_DROP_FILES;
                if event.files.count > 0 {
                    free(data);
                    data = read_entire_file(event.files[0]);
                }
            }
        }

        draw_one_frame(dt);

        reset_temporary_storage();
        sleep_milliseconds(10);
    }
}



draw_one_frame :: (dt: float) {
    background_shade :: 0.15;
    Simp.clear_render_target(background_shade, background_shade, background_shade, 1);

    x, y, width, height := get_dimensions(main_window, true);
    ui_per_frame_update(main_window, width, height, current_time);

    grid_width  : int = xx (window_width * 0.6);
    grid_height : int = xx (window_height - 100);

    button_width :: 24;
    button_height :: 24;
    padding :: 5;
    cell_width ::  button_width  + padding;
    cell_height :: button_height + padding;

    rows    := grid_height / cell_height;
    columns := grid_width / cell_width;

    grid_x :: 20;
    grid_y :: 20 + cell_height;

    data_index := 0;
    for row: 0 .. rows - 1 {
        for column: 0 .. columns - 1 {
            label := ifx data_index < data.count
                    then tprint("%", formatInt(data[data_index], base=16, minimum_digits=2))
                    else "";

            r := rect(column * cell_width + grid_x, window_height - (row * cell_height + grid_y), button_width, button_height);
            if button(r, label, *button_theme, data_index)
                last_clicked = label;

            data_index += 1;
        }
    }

    text_margin :: 10;
    text_x := grid_x + grid_width + text_margin;
    text_y := grid_y;
    text_width  := 16;
    text_height := button_height;

    data_index = 0;
    for row: 0 .. rows - 1 {
        for column: 0 .. columns - 1 {
            label : string = ---;
            if data_index < data.count {
                if data[data_index] >= #char " " {
                    label.data = *data[data_index];
                    label.count = 1;
                }
                else {
                    label = "·";
                }
            }
            else {
                label = "";
            }

            r := rect(column * text_width + text_x, window_height - (row * cell_height + grid_y), text_width, cell_height);
            if button(r, label, *button_theme, data_index)
                last_clicked = label;

            data_index += 1;
        }
    }

    {
        r := rect(10, 10, 30, 30);
        button(r, last_clicked, *button_theme);
    }

    {
        quit_width :: 100;
        quit_height :: 50;
        r := rect(window_width - quit_width - 10, 10, quit_width, quit_height);
        quit = button(r, "Quit!", *button_theme);
    }
    Simp.swap_buffers(main_window);
}


rect :: (x: int, y: int, w: int, h: int) -> Rect {
    return get_rect(xx x, xx y, xx w, xx h);
}


init_fonts :: () {
    if !working_directory_set {
        // So that we can load our font, set to path of running executable.
        path := jai_string.path_strip_filename(system.get_path_of_running_executable());
        set_working_directory(path);

        working_directory_set = true;
    }

    fontname :: "InconsolataGo-Regular.ttf";

    pixel_height := 24;
    main_font = Simp.get_font_at_size("data", fontname, pixel_height);
    assert(main_font != null);
}


setup_theme :: () {
    shape :: Rectangle_Shape.{
        roundedness = 0,
        frame_thickness = 0,
    };

    button_theme.font = main_font;
    button_theme.rectangle_shape = shape;
    button_theme.label_theme.alignment = .Center;
}


Font :: Simp.Dynamic_Font;
main_font:     *Font;
button_theme: Button_Theme;

working_directory_set := false;
