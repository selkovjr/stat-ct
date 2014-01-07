#!/usr/bin/perl -w

use strict;
use CGI;

my $cgi = new CGI;

my $dir = `pwd`;
chomp $dir;
$dir = (split '/', $dir)[-2]; # parent dir

print $cgi->header;

print $cgi->start_html(
		       -title => "The University of Chicago Surgical Training and Assessment Tool", 
		       -style => {-code => <<END}
li {
  margin-bottom: 1em;
  margin-top: 0.25em;
}
END
		      );
print $cgi->h2("The University of Chicago Surgical Training and Assessment Tool");
print $cgi->p(<<END
Welcome to the University of Chicago Surgical Training &
Assessment Tool ("STAT"). This is the demonstration site
only. Multiple users are able to enter data into it; all data entered
is make-believe. If system appears suitable, a genuine site can be
generated for dedicated use by your institution. Instructions for
trial are as follows:
END
);

print <<END
<ol>
  <li>
    Here is the link for the site: <a href=".." target="demo">http://cci.uchicago.edu/$dir</a>
  </li>

  <li>
    Site will ask for username and for password:
    <ul>
      <li>
        Decide the role in which you wish to log in (either "attending" or "trainee")
      </li>
      <li>
        <p>Pick one of these user IDs for the role you chose:</p>
        <table cellspacing="0" border>
          <tr>
            <td>Trainee</td> <td>Attending</td>
          </tr>
          <tr>
            <td>
              <code>
acooper apare barnard bbigelow blalock celsus cmayo dharken fbanting fogarty fred ftrend garret granv hboer hgillies ignaz jb jenner jfinney jhunter john lcourv lewis lister mcindoe morel mwalker nshum paget pancoast ramstedt robb tbill vanburen victor vmott vthomas wcowper wlill
              </code>
            </td>
            <td>
              <code>
acolles akhalaf cbailey chuette claude cushing dlarrey dmelrose elrazi halsted ilizarov lars lmott maltz mcdowell mevans percy sdgross thomas wilms wimc
              </code>
            </td>
          </tr>
        </table>
      </li>
      <li>
        Enter a password: The password for all users is "<code>pass</code>".
      </li>
    </ul>
    <div style="background-color: #ddd"; border: 1px">
      <b><em>Note</em>:</b> Whenever you want to log in as a different user, you must quit your browser application (not just close the window) and start again
    </div>
  </li>

  <li>
    Having logged in, use the tree menu to select a specific
    procedure; enter a date for when tho procedure occurred, and enter a
    name or ID of the other person with whom you operated (if
    you are an attending, pick an ID from the trainee list above, and vice versa
  </li>

  <li>
    Click "Proceed"
  </li>

  <li>
    <p>
      Make your assessment of the educational element of the case. Note that the sections for general qualities and for elements specific to any given case expand into greater detail and can be assessed at any level. At a minimum, you have to make a click per section, in all sections visible at the top level.
    </p>
    <p>
      The "Remarks" section is optional; it preserves any observations you wish to make.
    </p>
    <p>
      Conclude with a summative grade under "overall case assessment."
    </p>
  </li>

  <li>Click "Submit"</li>

  <li>
    To examine one's personal results and to conduct a progress review, click "Results" on the taskbar
    <ul>
      <li>
        In an operating system, we try to do a progress review with both trainee & attending present, once every two weeks
      </li>
      <li>
        Trainee data for the period is reviewed, an improvement plan for the trainee is agreed upon and entered into the dialogue box present, and the trainee signs the session by entering his/her password
      </li>
    </ul>
  </li>

  <li>
    <p>
      To examine results from a Program Director's perspective, log in as an attending and click on "Overview."
    </p>
    <p>
     In an operating system, only the PD or his/her designate can view everyone's data in the "Results" section or view the "Overview" section; in this demo version, all attendings can.
    </p>
  </li>

</ol>

<p>
  This set of instructions is to get you started so you can develop
  a "feel" for the system. Note that there is a "Help" function in the
  upper right part of the screen. Please feel free to contact us with
  any questions or comments.
</p>

<p>
 <a href="mailto:roach\@uchicago.edu">Paul Roach, MD</a>
</p>
END
;

