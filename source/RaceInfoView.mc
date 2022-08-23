import Toybox.Activity;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Test;
import Toybox.WatchUi;

class Note {
    var mLocation as Float;
    var mText as String;
    public function initialize(location as Float, text as String) {
      mLocation = location;
      mText = text;
    }
}

class Measures {

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
            if (location != null && distance > location) {
                return i;
            }
        }
        if (notes.size() == 0) {
            return 0;
        } else {
            return notes.size();
        }
    }

    function notesWithinRange(notes as Array<Note>, distance as Float, passedCount as Long) as Array<Note> {
        Test.assert(passedCount >= 0);
        var position = findNearest(notes, distance);
        position = position - passedCount;
        if (position < 0) {
            position = 0;
        }
        return notes.slice(position, notes.size());
    }

    function notesToText(notes as Array<Note>, distance as Float) as String {
        if (notes.size() == 0) {
            return "No notes found";
        }
        var output = "";
        for (var i = 0; i < notes.size(); i++) {
            var note = notes[i];
            if (distance != null && note.mLocation != null && note.mLocation > distance) {
                output = output + "*";
            }
            output = output + note.mText;
            output = output + "\n";
        }
        return output;
    }

    function calculate(raceNotes as String, passedCount as Number, distance as Float) as String {
        var notes = parseProperties(raceNotes);
        var ranged = notesWithinRange(notes, distance, passedCount);
        return notesToText(ranged, distance);
    }

}

function assertEqual(value1 as Lang.Object, value2 as Lang.Object) as Void {
    if (!value1.equals(value2)) {
        var message = "Expected equals, but got: " + value1 + " != " + value2;
        Test.assertMessage(false, message);
    }
}

function assertNull(value as Lang.Object) as Void {
    if (value != null) {
        var message = "Expected equals, null, but got: " + value;
        Test.assertMessage(false, message);
    }
}

(:test)
function verifyNoteIsParsed(logger as Logger) as Boolean {
    var measures = new Measures();
    var note = measures.parseNote("124km - Orlen (24h) - Mrągowo");
    assertEqual(note.mLocation, 124000f);
    assertEqual(note.mText, "124km - Orlen (24h) - Mrągowo");
    return true;
}

(:test)
function verifyNoteWithoutLocationIsParsed(logger as Logger) as Boolean {
    var measures = new Measures();
    var note = measures.parseNote("Orlen - Mrągowo");
    assertNull(note.mLocation);
    assertEqual(note.mText, "Orlen - Mrągowo");
    return true;
}


(:test)
function verifyParseNotesWithOneNote(logger as Logger) as Boolean {
    var measures = new Measures();
    var notes = measures.parseProperties("124km - Orlen (24h) - Mrągowo");
    assertEqual(notes.size(), 1);
    assertEqual(notes[0].mText, "124km - Orlen (24h) - Mrągowo");
    return true;
}


(:test)
function verifyParseNotesWithNoNotes(logger as Logger) as Boolean {
    var measures = new Measures();
    var notes = measures.parseProperties("");
    assertEqual(notes.size(), 0);
    return true;
}

(:test)
function verifyParseNotesWithMultipleNotes(logger as Logger) as Boolean {
    var measures = new Measures();
    var notes = measures.parseProperties("124km - Orlen (24h) - Mrągowo,150km - BP +5km - Pisz");
    assertEqual(notes.size(), 2);
    assertEqual(notes[0].mText, "124km - Orlen (24h) - Mrągowo");
    assertEqual(notes[1].mText, "150km - BP +5km - Pisz");
    return true;
}

(:test)
function verifyNotesWithinRange(logger as Logger) as Boolean {
    var measures = new Measures();
    var all = [
        new Note(700f, "700"),
        new Note(600f, "600"),
        new Note(500f, "500"),
        new Note(400f, "400"),
        new Note(300f, "300"),
        new Note(200f, "200"),
        new Note(100f, "100"),
    ];
    var displayed = measures.notesWithinRange(all, 399, 0);
    assertEqual(displayed[0].mLocation, 300f);
    assertEqual(displayed[1].mLocation, 200f);
    assertEqual(displayed[2].mLocation, 100f);
    assertEqual(displayed.size(), 3);
    return true;
}

(:test)
function verifyNotesWithinRangeWithPassedCount(logger as Logger) as Boolean {
    var measures = new Measures();
    var all = [
        new Note(700f, "700"),
        new Note(600f, "600"),
        new Note(500f, "500"),
        new Note(400f, "400"),
        new Note(300f, "300"),
        new Note(200f, "200"),
        new Note(100f, "100"),
    ];
    var displayed = measures.notesWithinRange(all, 399, 2);
    assertEqual(displayed[0].mLocation, 500f);
    assertEqual(displayed[1].mLocation, 400f);
    assertEqual(displayed[2].mLocation, 300f);
    assertEqual(displayed[3].mLocation, 200f);
    assertEqual(displayed[4].mLocation, 100f);
    assertEqual(displayed.size(), 5);
    return true;
}


(:test)
function verifyNotesWithinRangeAtStart(logger as Logger) as Boolean {
    var measures = new Measures();
    var all = [
        new Note(400f, "400"),
        new Note(300f, "300"),
        new Note(200f, "200"),
        new Note(100f, "100"),
    ];
    var displayed = measures.notesWithinRange(all, 500f, 2);
    assertEqual(displayed[0].mLocation, 400f);
    assertEqual(displayed[1].mLocation, 300f);
    assertEqual(displayed[2].mLocation, 200f);
    assertEqual(displayed[3].mLocation, 100f);
    assertEqual(displayed.size(), 4);
    return true;
}

(:test)
function verifyNotesWithinRangeAtEnd(logger as Logger) as Boolean {
    var measures = new Measures();
    var all = [
        new Note(400f, "400"),
        new Note(300f, "300"),
        new Note(200f, "200"),
        new Note(100f, "100"),
    ];
    var displayed = measures.notesWithinRange(all, 0f, 2);
    assertEqual(displayed[0].mLocation, 200f);
    assertEqual(displayed[1].mLocation, 100f);
    assertEqual(displayed.size(), 2);
    return true;
}


(:test)
function verifyNotesWithNoInput(logger as Logger) as Boolean {
    var measures = new Measures();
    assertEqual(measures.notesWithinRange([], 0f, 2).size(), 0);
    assertEqual(measures.notesWithinRange([], 0f, 0).size(), 0);
    return true;
}


(:test)
function verifyAllAtStart(logger as Logger) as Boolean {
    var measures = new Measures();
    var input = "500km - A,400km - B,300km - C,200km - D,100km - E";
    var output = measures.calculate(input, 2, 600000f);

    assertEqual(output, "500km - A\n400km - B\n300km - C\n200km - D\n100km - E\n");
    return true;
}

(:test)
function verifyAllAtTheMiddle(logger as Logger) as Boolean {
    var measures = new Measures();
    var input = "500km - A,400km - B,300km - C,200km - D,100km - E";
    var output = measures.calculate(input, 2, 199000f);

    assertEqual(output, "*300km - C\n*200km - D\n100km - E\n");
    return true;
}

(:test)
function verifyAllAtTheEnd(logger as Logger) as Boolean {
    var measures = new Measures();
    var input = "500km - A,400km - B,300km - C,200km - D,100km - E";
    var output = measures.calculate(input, 2, 0f);

    assertEqual(output, "*200km - D\n*100km - E\n");
    return true;
}

class RaceInfoView extends WatchUi.DataField {

    hidden var mValue as Numeric;
    hidden var mMeasures as Measures;

    function initialize() {
        DataField.initialize();
        mMeasures = new Measures();
        mValue = 0.0f;
    }

    // Set your layout here. Anytime the size of obscurity of
    // the draw context is changed this will be called.
    function onLayout(dc as Dc) as Void {
        View.setLayout(Rez.Layouts.MainLayout(dc));
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
        var label = View.findDrawableById("label") as Text;
        if (getBackgroundColor() == Graphics.COLOR_BLACK) {
            value.setColor(Graphics.COLOR_WHITE);
        } else {
            value.setColor(Graphics.COLOR_BLACK);
        }
        var labelText = "";
        if (mValue != null) {
            labelText = WatchUi.loadResource(Rez.Strings.label) + (mValue/1000.0).format("%.0f") + "km";
        }
        label.setText(labelText);
        value.setText(calculate());

        // Call parent's onUpdate(dc) to redraw the layout
        View.onUpdate(dc);
    }

    function calculate() as String {
        if (mValue == null) {
            return "Navigation not started";
        }
        
        var raceNotes = Application.getApp().getProperty("raceNotes");
        var passedCount = Application.getApp().getProperty("passedCount");
        
        return mMeasures.calculate(raceNotes, passedCount, mValue);
    }

}
