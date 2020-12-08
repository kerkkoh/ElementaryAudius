/*
* Idk why I'm even including this license in here. I guess no warranty? YEAH! No warranty! You heard me.
*
* The MIT License (MIT)
*
* Copyright (c) 2020 Kerkkoh
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*
* Authored by: Kerkkoh <superihippo@gmail.com>
*/

public class Application : Gtk.Application {

    private static StreamPlayer player;
    private bool has_played = false;
    private bool show_notifications = true;

    public Application () {
        Object (
            application_id: "com.github.ElementaryAudius",
            flags: ApplicationFlags.FLAGS_NONE
        );
    }

    private void show_notification (string title, string body, string icon = "applications-multimedia") {
        if (!show_notifications) return;

        var notification = new Notification (_(title));
        notification.set_body (_(body));
        notification.set_icon (new GLib.ThemedIcon (icon));
        send_notification ("com.github.kerkkoh.ElementaryAudius", notification);
    }

    private void play(ref Gtk.LinkButton link_button, ref Gtk.Label playing_label, ref Gtk.Image album_art, bool in_order, int delta = 0) {
        player.get_trending (in_order, delta);
        player.stop ();
        player.play ();
    }

    private void pause_or_play (ref Gtk.LinkButton link_button, ref Gtk.Label playing_label, ref Gtk.Image album_art, ref Gtk.Button pause_button, ref Gtk.Button play_button) {
        if (!has_played) {
            play(ref link_button, ref playing_label, ref album_art, true, 0);
            has_played = true;
        }
        if (player.is_playing ()) {
            pause_button.hide();
            play_button.show();
        } else {
            play_button.hide();
            pause_button.show();
        }
        player.pause ();
    }

    private void update_duration_bar (int64 current, int64 duration, ref Gtk.Label duration_label) {
        string duration_bar = "";
        double curr = (double) current;
        double durr = (double) duration;
        int done = (int) ((curr/durr) * 10);
        if (done == 0) duration_bar += ">";
        for (int i = 0; i < done; i++) {
            if (i == done - 1) duration_bar += ">";
            else duration_bar += "-";
        }
        for (int i = 0; i < 9-done; i++) {
            duration_bar += "#";
        }
        duration_label.set_label(_(current.to_string() + " " + duration_bar + " " + duration.to_string()));
    }

    protected override void activate () {
        var main_window = new Gtk.ApplicationWindow (this);
        main_window.set_icon_name("applications-multimedia");
        main_window.default_height = 300;
        main_window.default_width = 280;
        main_window.title = "ElementaryAudius";
        var title_label = new Gtk.Label (_("Now playing:"));
        var playing_label = new Gtk.Label (_("Loading Audius..."));
        var album_art = new Gtk.Image ();
        var duration_label = new Gtk.Label (_(""));
        var random_button = new Gtk.Button.with_label (_("Play random trending track"));
        var previous_button = new Gtk.Button.from_icon_name("media-skip-backward-symbolic");
        var next_button = new Gtk.Button.from_icon_name("media-skip-forward-symbolic");
        var pause_button = new Gtk.Button.from_icon_name("media-playback-pause-symbolic");
        var play_button = new Gtk.Button.from_icon_name("media-playback-start-symbolic");
        var show_notif_toggle = new Gtk.Switch ();
        show_notif_toggle.set_active(true);
        var show_notif_label = new Gtk.Label(_("Show notifications"));
        var link_button = new Gtk.LinkButton.with_label ("https://audius.co/trending", _("Open this track on Audius.co"));
        
        var grid = new Gtk.Grid ();
        grid.orientation = Gtk.Orientation.VERTICAL;
        grid.row_spacing = 6;
        grid.column_spacing = 6;
        // Very sketchy padding work here buddy
        var padding_left = new Gtk.Label (_(" "));
        var padding_right = new Gtk.Label (_(" "));
        grid.attach(padding_left, -1, 99, 1, 1);
        grid.attach(padding_right, 2, 99, 1, 1);
        grid.add (title_label);
        grid.add (playing_label);
        grid.add (album_art);
        grid.add (duration_label);
        grid.add (random_button);
        var buttons = new Gtk.Grid ();
        buttons.attach(previous_button, 0, 0, 1, 1);
        buttons.attach(pause_button, 1, 0, 1, 1);
        buttons.attach(play_button, 1, 0, 1, 1);
        buttons.attach(next_button, 2, 0, 1, 1);
        grid.add(buttons);
        var notif_grid = new Gtk.Grid ();
        notif_grid.column_spacing = 6;
        // var notif_padding = new Gtk.Label (_(" "));
        notif_grid.attach(show_notif_toggle, 0, 0, 1, 1);
        // notif_grid.attach(notif_padding, 1, 0, 1, 1);
        notif_grid.attach(show_notif_label, 2, 0, 1, 1);
        grid.add (notif_grid);
        grid.add (link_button);

        title_label.set_hexpand (true);
        playing_label.set_hexpand (true);
        playing_label.set_line_wrap(true);
        playing_label.set_justify (Gtk.Justification.CENTER);
        album_art.set_hexpand (true);
        duration_label.set_hexpand (true);
        random_button.set_hexpand (true);
        previous_button.set_hexpand (true);
        next_button.set_hexpand (true);
        play_button.set_hexpand (true);
        pause_button.set_hexpand (true);
        show_notif_label.set_justify (Gtk.Justification.LEFT);
        link_button.set_hexpand (false);

        random_button.clicked.connect (() => {
            play(ref link_button, ref playing_label, ref album_art, false);
        });
        previous_button.clicked.connect (() => {
            play(ref link_button, ref playing_label, ref album_art, true, -1);
        });
        next_button.clicked.connect (() => {
            play(ref link_button, ref playing_label, ref album_art, true, 1);
        });
        pause_button.clicked.connect (() => {
            pause_or_play(ref link_button, ref playing_label, ref album_art, ref pause_button, ref play_button);
        });
        play_button.clicked.connect (() => {
            pause_or_play(ref link_button, ref playing_label, ref album_art, ref pause_button, ref play_button);
        });
        show_notif_toggle.state_set.connect (() => {
            show_notifications = !show_notif_toggle.get_state();
            return false;
        });

        main_window.add (grid);
        main_window.show_all ();
        pause_button.hide();
        buttons.hide();

        bool is_ready = false;
        var track_time = new TimeoutSource(1000);

        player = new StreamPlayer (ref is_ready, ref track_time);

        track_time.attach(null);

        player.song_changed.connect (() => {
            var some_track = player.get_current_track ();

            link_button.set_uri("https://audius.co/tracks/"+some_track.id);
    
            playing_label.set_label(some_track.user.name + " - " + some_track.title);
            album_art.set_from_pixbuf(player.get_current_track_image ());

            update_duration_bar (player.current_seconds, some_track.duration, ref duration_label);
    
            show_notification(some_track.title, "By " + some_track.user.name);
        });
        player.play_state_changed.connect ((new_state) => {
            if (new_state != Gst.State.PLAYING) {
                pause_button.hide();
                play_button.show();
            } else {
                play_button.hide();
                pause_button.show();
            }
        });
        player.has_notification.connect ((title, body, icon) => {
            show_notification(title, body, icon);
        });
        player.duration_tick.connect ((current_seconds) => {
            update_duration_bar (current_seconds, (player.get_current_track ()).duration, ref duration_label);
        });

        var time = new TimeoutSource(100);
        time.set_callback(() => {
            if (is_ready) {
                playing_label.set_label("Press play!");
                buttons.show();
                Gtk.main_quit();
                return false;
            }
            return true;
        });
        time.attach(null);

        Gtk.main();
    }

    public static int main (string[] args) {
        Gst.init (ref args);
        var app = new Application ();
        return app.run (args);
    }
}

