#!/bin/sh

set -eu

TITLE="${TITLE:-"Rickroll"}"
HEIGHT="${HEIGHT:-"100vh"}"
WIDTH="${WIDTH:-"100%"}"
HEADLINE="${HEADLINE:-""}"
#Create index.html
tee /usr/share/nginx/html/index.html << EOF >/dev/null
<!DOCTYPE html>
<html>
   <body>
       <video autoplay loop width="100%">

    <source src="video.mp4"
            type="video/mp4">

    Sorry, your browser doesn't support embedded videos.
</video>
      <style>
          video {
              height: $HEIGHT;
              width: $WIDTH;
              object-fit: cover; /**/ use "cover" to avoid distortion
              position: absolute;
          }
      </style>
      <script>
         // Change the variables below to your liking
         const currentURL = "video.mp4";
         const pageTitle = "Loading...";
         // End of changable variables
         
         function setTitle() {
            document.title = pageTitle;
         }
         
         function redirect() {
            window.location.href = currentURL;
         }
         
         function onload() {
            setTitle();
            redirect();
         }
         
         window.onload = onload();
       </script>
<footer class="footer-1 footer reveal-side-navigation">
				<div class="footer-bottom center">
					<div class="row">
						<div class="column width-12">
							<div class="footer-bottom-inner">
								<p class="copyright no-margin-bottom">© 2021 <a rel="me" href="https://mastodon.social/@hyperjinx">RALPH CASPERS</a></p>
							</div>
						</div>
					</div> 
				</div>
			</footer>
   
   
   
   </body>
</html>
EOF

echo ""
echo "#####################"
echo "Website title is: $TITLE"
echo "Website height: $HEIGHT"
echo "Website width: $WIDTH"
echo "Headline is: $HEADLINE"
echo "#####################"
echo ""

exec "$@"
