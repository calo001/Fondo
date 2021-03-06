/*
* Copyright (C) 2018  Calo001 <calo_lrc@hotmail.com>
*
* This program is free software: you can redistribute it and/or modify
* it under the terms of the GNU Affero General Public License as published
* by the Free Software Foundation, either version 3 of the License, or
* (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
* GNU Affero General Public License for more details.
*
* You should have received a copy of the GNU Affero General Public License
* along with this program.  If not, see <http://www.gnu.org/licenses/>.
*
*/

using App.Configs;
using App.Models;

namespace App.Connection {

     /**
     * The {@code AppConnection} class.
     *
     * @since 1.0.0
     */

    public class AppConnection {

        public signal void request_page_success(List<Photo?> list);
        public signal void request_page_search_success(SearchResult result);

        private static AppConnection? instance;
        private Soup.Session session;

        public AppConnection() {
            this.session = new Soup.Session();
            this.session.ssl_strict = false;
        }

        // Parse data from API
        public void load_page (int num_page) {
            var uri = Constants.URI_PAGE +
                      "&page=" + num_page.to_string() +
                      "&per_page=" + "30" +
                      "&order_by=" + "latest";

            //var uri = "http://jsonplaceholder.typicode.com/todos/1";
            var message = new Soup.Message ("GET", uri);

            session.queue_message (message, (sess, mess) => {
                if (mess.status_code == 200) {
                    var parser = new Json.Parser ();
                    try {
                        parser.load_from_data ((string) mess.response_body.flatten ().data, -1);
                        var list = get_data (parser);
                        request_page_success(list);
                    } catch (Error e) {
                        show_message("Request page fail", e.message, "dialog-error");
                    }
                } else {
                    show_message("Request page fail", @"status code: $(mess.status_code)", "dialog-error");
                }
            });
        }

        public void load_search_page (int num_page, string query) {
            var uri = Constants.URI_SEARCH_PAGE +
            "&query=" + query +
            "&page=" + num_page.to_string() +
            "&per_page=" + "30";

            var message = new Soup.Message ("GET", uri);

            session.queue_message (message, (sess, mess) => {
                if (mess.status_code == 200) {
                    print((string) mess.response_body);
                    var parser = new Json.Parser ();
                    try {
                        parser.load_from_data ((string) mess.response_body.flatten ().data, -1);
                        var list = get_data_search (parser);
                        request_page_search_success(list);
                    } catch (Error e) {
                        show_message("Request page fail", e.message, "dialog-error");
                    }
                } else {
                    show_message("Request page fail", @"status code: $(mess.status_code)", "dialog-error");
                }
            });
        }

        private List<Photo?> get_data (Json.Parser parser) {
            Json.Node node = parser.get_root ();
            return PhotoUtil.from_json (node);
        }

        // Create all structure Photo
        private SearchResult get_data_search (Json.Parser parser) {
            var node = parser.get_root ();
            return SearchResultUtil.from_json (node);
        }

        // Get an image from: links_download_location
        public string? get_url_photo (string id) {
            string uri = @"$(Constants.API_UNSPLASH)/photos/$(id)/download?client_id=$(Constants.ACCESS_KEY_UNSPLASH)";

            var message = new Soup.Message ("GET", uri);
            string? image = null;

            MainLoop loop = new MainLoop ();
            session.queue_message (message, (sess, mess) => {
                var parser = new Json.Parser ();
                try {
                    //parser.load_from_data ((string) message.response_body.flatten ().data, -1);
                    parser.load_from_data ((string) mess.response_body.flatten ().data, -1);
                    var node = parser.get_root ();
                    image = node.get_object ().get_string_member ("url");
                    loop.quit ();
                } catch (Error e) {
                    show_message("Unable to parse the string",
                                  e.message,
                                  "dialog-error");
                }
            });
            loop.run ();
            return image;
        }

        /**
         * Returns a single instance of this class.
         *
         * @return {@code AppConnection}
         */
        public static unowned AppConnection get_instance () {
            if (instance == null) {
                instance = new AppConnection ();
            }
            return instance;
        }

        /************************************
           Dialog that show error messages
        ************************************/
        private void show_message (string txt_primary, string txt_secondary, string icon) {
            var message_dialog = new Granite.MessageDialog.with_image_from_icon_name (
                txt_primary,
                txt_secondary,
                icon,
                Gtk.ButtonsType.CLOSE
            );

            message_dialog.run ();
            message_dialog.destroy ();
        }
    }
}
