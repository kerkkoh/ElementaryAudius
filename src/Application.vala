/*
* Copyright (c) 2020 - Today kerkkoh ()
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 2 of the License, or (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* General Public License for more details.
*
* You should have received a copy of the GNU General Public
* License along with this program; if not, write to the
* Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
* Boston, MA 02110-1301 USA
*
* Authored by: kerkkoh <superihippo@gmail.com>
*/

struct User {
    int64 album_count;
    string bio;
    string	cover_photo;
    int64 followee_count;
    int64 follower_count;
    string handle;
    string id;
    bool is_verified;
    string location;
    string name;
    int64 playlist_count;
    int64 repost_count;
    int64 track_count;
}
struct Track_Artwork {
    string img_150x150;
    string img_480x480;
    string img_1000x1000;
}
struct Track {
    Track_Artwork artwork;
    string description;
    string genre;
    string id;
    string mood;
    string release_date;
    string remix_parent_id;
    int64 repost_count;
    int64 favorite_count;
    string tags;
    string title;
    User user;
    int64 duration;
    bool downloadable;
    int64 play_count;
}

public class Application : Gtk.Application {

    private static string api_endpoint = "https://discoveryprovider.audius.co";
    private static StreamPlayer player;
    private Json.Array tracks = new Json.Array ();
    private int32 total_tracks = 0;
    private uint track_idx = 0;

    public Application () {
        Object (
            application_id: "com.github.ElementaryAudius",
            flags: ApplicationFlags.FLAGS_NONE
        );
    }

    private void get_api_endpoint () {
        var uri = "https://api.audius.co/";

        var session = new Soup.Session ();
        var message = new Soup.Message ("GET", uri);
        session.send_message (message);

        try {
            var parser = new Json.Parser ();
            parser.load_from_data ((string) message.response_body.flatten ().data, -1);
    
            var root_object = parser.get_root ().get_object ();
            var response = root_object.get_array_member ("data");
            
            int32 total = (int32) response.get_length ();
            uint rand = (uint) GLib.Random.int_range(0, total);

            api_endpoint = response.get_string_element(rand);

            stdout.printf ("New api endpoint: %s\n", api_endpoint);
        } catch (Error e) {
            stderr.printf ("I guess something is not working...\n");
        }
    }

    // Catch me if you can
    private Json.Array req_data_array(string route) throws Error {
        var session = new Soup.Session ();
        var message = new Soup.Message ("GET", api_endpoint+"/v1/"+route);
        // print(api_endpoint+"/v1/"+route);
        session.send_message (message);

        var parser = new Json.Parser ();
        parser.load_from_data ((string) message.response_body.flatten ().data, -1);

        var root_object = parser.get_root ().get_object ();
        return root_object.get_array_member ("data");
    }

    // Catch me if you can
    private Track process_track_object(Json.Object raw_track) throws Error {
        var raw_user = raw_track.get_object_member ("user");
        var raw_artwork = raw_track.get_object_member ("artwork");

        return Track() {
            artwork = Track_Artwork () {
                img_150x150 = raw_artwork.get_string_member ("150x150"),
                img_480x480 = raw_artwork.get_string_member ("480x480"),
                img_1000x1000 = raw_artwork.get_string_member ("1000x1000")
            },
            id = raw_track.get_string_member ("id"),
            title = raw_track.get_string_member ("title"),
            user = User() {
                id = raw_user.get_string_member ("id"),
                handle = raw_user.get_string_member ("handle"),
                name = raw_user.get_string_member ("name")
            }
        };
    }

    private Gdk.Pixbuf get_image (string uri) {
        print("get_image\n");
        var session = new Soup.Session ();
        var message = new Soup.Message ("GET", uri);
        session.send_message (message);

        var mem_ipt_stream = new GLib.MemoryInputStream.from_data(message.response_body.data);
        return new Gdk.Pixbuf.from_stream(mem_ipt_stream);
        // stdout.printf("%d x %d\n", pixbuf.width, pixbuf.height);
    }

    private Track get_trending (bool in_order = true) {
        try {
            total_tracks = (int32) tracks.get_length ();
            if (in_order) {
                track_idx++;
            } else {
                track_idx = (uint) GLib.Random.int_range(0, total_tracks);
            }

            if (track_idx >= total_tracks) track_idx = 0;

            return process_track_object(tracks.get_object_element (track_idx));
        } catch (Error e) {
            stderr.printf ("I guess something is not working...\n");

            var notification = new Notification (_("Error...\n"));
            notification.set_body (_("My bad, something's not working again..."));
            send_notification ("com.github.kerkkoh.ElementaryAudius", notification);

            return Track() {title = ""};
        }
    }

    private void play(bool in_order, ref Gtk.LinkButton link_button, ref Gtk.Label playing_label, ref Gtk.Image album_art) {
        var some_track = get_trending (in_order);

        link_button.set_uri("https://audius.co/tracks/"+some_track.id);

        // print(api_endpoint + "/v1/tracks/" + some_track.id + "/stream");
        player.stop ();
        player.play (api_endpoint + "/v1/tracks/" + some_track.id + "/stream");

        playing_label.set_label(some_track.user.name + " - " + some_track.title);
        album_art.set_from_pixbuf(get_image (some_track.artwork.img_150x150));

        var notification = new Notification (_(some_track.title));
        notification.set_body (_("By " + some_track.user.handle));
        notification.set_icon (new GLib.ThemedIcon ("applications-multimedia"));
        send_notification ("com.github.kerkkoh.ElementaryAudius", notification);
    }

    protected override void activate () {
        get_api_endpoint();
        tracks = req_data_array ("tracks/trending");
        var main_window = new Gtk.ApplicationWindow (this);
        main_window.set_icon_name("applications-multimedia");
        main_window.default_height = 400;
        main_window.default_width = 280;
        main_window.title = "ElementaryAudius";
        var title_label = new Gtk.Label (_("Now playing:"));
        var playing_label = new Gtk.Label (_("... ... ... ..."));
        var album_art = new Gtk.Image ();
        var play_button = new Gtk.Button.with_label (_("Play random trending track"));
        var play_in_order_button = new Gtk.Button.with_label (_("Play next trending track"));
        var stop_button = new Gtk.Button.with_label (_("Stop"));
        var pause_button = new Gtk.Button.with_label (_("Pause"));
        var link_button = new Gtk.LinkButton.with_label ("https://audius.co/trending", _("Open this track on Audius.co"));
        
        var grid = new Gtk.Grid ();
        grid.orientation = Gtk.Orientation.VERTICAL;
        grid.row_spacing = 6;
        grid.column_spacing = 6;
        // really? really.
        var padding_left = new Gtk.Label (_(" "));
        var padding_right = new Gtk.Label (_(" "));
        grid.attach(padding_left, -1, 99, 1, 1);
        grid.attach(padding_right, 2, 99, 1, 1);
        grid.add (title_label);
        grid.add (playing_label);
        grid.add (album_art);
        grid.add (play_button);
        grid.add (play_in_order_button);
        grid.add (stop_button);
        grid.add (pause_button);
        grid.add (link_button);
        player = new StreamPlayer ();

        title_label.set_hexpand(true);
        playing_label.set_hexpand(true);
        album_art.set_hexpand(true);
        play_button.set_hexpand(true);
        play_in_order_button.set_hexpand(true);
        stop_button.set_hexpand(true);
        pause_button.set_hexpand(true);
        link_button.set_hexpand(true);

        play_button.clicked.connect (() => {
            play(false, ref link_button, ref playing_label, ref album_art);
        });
        play_in_order_button.clicked.connect (() => {
            play(true, ref link_button, ref playing_label, ref album_art);
        });
        stop_button.clicked.connect (() => {
            player.stop ();
        });
        pause_button.clicked.connect (() => {
            player.pause ();
        });

        main_window.add (grid);
        main_window.show_all ();
    }

    public static int main (string[] args) {
        Gst.init (ref args);
        var app = new Application ();
        return app.run (args);
    }
}

