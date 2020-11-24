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
struct Track {
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

    public Application () {
        Object (
            application_id: "com.github.ElementaryAudius",
            flags: ApplicationFlags.FLAGS_NONE
        );
    }

    private void get_api_endpoint () {
        var uri = "https://api.audius.co/";//"http://services.gisgraphy.com/fulltext/fulltextsearch?q=%s&format=JSON&indent=true&lang=en&from=1&to=10".printf ("asakusa");

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

    private Track get_trending () {
        var session = new Soup.Session ();
        var message = new Soup.Message ("GET", api_endpoint+"/v1/tracks/trending");
        session.send_message (message);
    
        try {
            var parser = new Json.Parser ();
            parser.load_from_data ((string) message.response_body.flatten ().data, -1);
    
            var root_object = parser.get_root ().get_object ();
            var response = root_object.get_array_member ("data");
            
            int32 total = (int32) response.get_length ();
            uint rand = (uint) GLib.Random.int_range(0, total);

            var raw_track = response.get_object_element(rand);
            var raw_user = raw_track.get_object_member ("user");

            var track = Track() {
                id = raw_track.get_string_member ("id"),
                title = raw_track.get_string_member ("title"),
                user = User() {
                    id = raw_user.get_string_member ("id"),
                    handle = raw_user.get_string_member ("handle"),
                    name = raw_user.get_string_member ("name")
                }
            };

            return track;

        } catch (Error e) {
            stderr.printf ("I guess something is not working...\n");
            return Track() {title = "Something went wrong..."};
        }
    }

    protected override void activate () {
        var main_window = new Gtk.ApplicationWindow (this);
        main_window.default_height = 300;
        main_window.default_width = 300;
        main_window.title = "ElementaryAudius";
        var title_label = new Gtk.Label (_("Notifications"));
        var show_button = new Gtk.Button.with_label (_("Show"));
        
        var grid = new Gtk.Grid ();
        grid.orientation = Gtk.Orientation.VERTICAL;
        grid.row_spacing = 6;
        grid.add (title_label);
        grid.add (show_button);
        get_api_endpoint();

        show_button.clicked.connect (() => {
            var some_track = get_trending ();

            player.play (api_endpoint + "/v1/tracks/" + some_track.id + "/stream");

            var notification = new Notification (_(some_track.title));
            notification.set_body (_("By " + some_track.user.handle));
        
            send_notification ("com.github.kerkkoh.ElementaryAudius", notification);
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

