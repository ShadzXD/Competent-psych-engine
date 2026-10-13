// @author Nebula_Zorua
package modchart;

import objects.notes.*;
import modchart.Modifier.ModifierType;

class NoteModifier extends Modifier
{
	override function getModType()
		return NOTE_MOD; // tells the mod manager to call this modifier when updating receptors/notes
}
