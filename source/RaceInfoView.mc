import Toybox.Activity;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

class Note {
    var mLocation;
    var mText;
    public function initialize(location, text) {
      mLocation = location;
      mText = text;
    }
}

class RaceInfoView extends WatchUi.DataField {

    hidden var mValue as Numeric;

    function initialize() {
        DataField.initialize();
        mValue = 0.0f;
    }

    // Set your layout here. Anytime the size of obscurity of
    // the draw context is changed this will be called.
    function onLayout(dc as Dc) as Void {
        var obscurityFlags = DataField.getObscurityFlags();

        // Top left quadrant so we'll use the top left layout
        if (obscurityFlags == (OBSCURE_TOP | OBSCURE_LEFT)) {
            View.setLayout(Rez.Layouts.TopLeftLayout(dc));

        // Top right quadrant so we'll use the top right layout
        } else if (obscurityFlags == (OBSCURE_TOP | OBSCURE_RIGHT)) {
            View.setLayout(Rez.Layouts.TopRightLayout(dc));

        // Bottom left quadrant so we'll use the bottom left layout
        } else if (obscurityFlags == (OBSCURE_BOTTOM | OBSCURE_LEFT)) {
            View.setLayout(Rez.Layouts.BottomLeftLayout(dc));

        // Bottom right quadrant so we'll use the bottom right layout
        } else if (obscurityFlags == (OBSCURE_BOTTOM | OBSCURE_RIGHT)) {
            View.setLayout(Rez.Layouts.BottomRightLayout(dc));

        // Use the generic, centered layout
        } else {
            View.setLayout(Rez.Layouts.MainLayout(dc));
            var labelView = View.findDrawableById("label");
            labelView.locY = labelView.locY - 16;
            var valueView = View.findDrawableById("value");
            valueView.locY = valueView.locY + 7;
        }

        (View.findDrawableById("label") as Text).setText(Rez.Strings.label);
    }

    // The given info object contains all the current workout information.
    // Calculate a value and save it locally in this method.
    // Note that compute() and onUpdate() are asynchronous, and there is no
    // guarantee that compute() will be called before onUpdate().
    function compute(info as Activity.Info) as Void {
        // See Activity.Info in the documentation for available information.
        if (info has :distanceToDestination) {
            if (info.distanceToDestination != null) {
                mValue = info.distanceToDestination as Number;
            } else {
                mValue = null;
            }
        }
    }

    // Display the value you computed here. This will be called
    // once a second when the data field is visible.
    function onUpdate(dc as Dc) as Void {
        // Set the background color
        (View.findDrawableById("Background") as Text).setColor(getBackgroundColor());

        // Set the foreground color and value
        var value = View.findDrawableById("value") as Text;
        if (getBackgroundColor() == Graphics.COLOR_BLACK) {
            value.setColor(Graphics.COLOR_WHITE);
        } else {
            value.setColor(Graphics.COLOR_BLACK);
        }
        value.setText(calculate());

        // Call parent's onUpdate(dc) to redraw the layout
        View.onUpdate(dc);
    }

    function extractLines(string as String, separator as String) as Array<String> {
        var input = string;
        var output = [];
        while (true) {
            if (input.length() == 0) {
                break;
            }
            var index = input.find(separator);
            if (index != null) {
                output.add(input.substring(0, index));
                input = input.substring(index + separator.length(), input.length());
            } else {
                output.add(input);
                break;
            }
        }
        return output;
    }

    function getDistanceFromNote(line as String) as Number {
        return line.toNumber();
    }

    function parseNote(line as String) as Note {
        var location = getDistanceFromNote(line);
        if (location != null) {
            location = 1000f * location;
        }
        return new Note(location, line);
    }

    function parseProperties(property as String) as Array<Note> {
        var lines = extractLines(property, ",");
        var notes = [];
        for (var i = 0; i < lines.size(); i++) {
            notes.add(parseNote(lines[i]));
        }
        return notes;
    }

    function findNearest(notes as Array<Note>, distance as Float) as Array<Note> {
        for (var i = 0; i < notes.size(); i++) {
            var location = notes[i].mLocation;
            if (location != null && location < distance) {
                return i;
            }
        }
        return 0;
    }

    function notesWithinRange(notes as Array<Note>, distance as Float, passedCount as Long) as Array<Note> {
        var position = findNearest(notes, distance);
        position = position - passedCount;
        if (position < 0) {
            position = 0;
        }
        return notes.slice(position, notes.size());
    }

    function notesToText(notes as Array<Note>) as String {
        if (notes.size() == 0) {
            return "No notes found";
        }
        var output = "";
        for (var i = 0; i < notes.size(); i++) {
            var note = notes[i];
            output = output + note.mText;
            output = output + "\n";
        }
        return output;
    }

    function calculate() as String {
        if (mValue == null) {
            return "Navigation not started";
        }
        var raceNotes = Application.getApp().getProperty("raceNotes");
        var passedCount = Application.getApp().getProperty("passedCount");
        
        var notes = parseProperties(raceNotes);
        // return notesToText(notes);
        var ranged = notesWithinRange(notes, mValue, passedCount);
        return notesToText(ranged);
    }

}
