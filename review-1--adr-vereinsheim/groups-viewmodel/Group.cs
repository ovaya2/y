// Ziel: yam2/Models/Group.cs
using System.ComponentModel.DataAnnotations;
using yam2.Core;

namespace yam2.Models
{
    public class Group : ObservableValidator
    {
        private int    _id;
        private string _bezeichnung = string.Empty;

        public int Id
        {
            get { return _id; }
            set { SetProperty(ref _id, value); }
        }

        [Required(ErrorMessage = "Bezeichnung ist erforderlich.")]
        [MaxLength(50, ErrorMessage = "Maximal 50 Zeichen.")]
        public string Bezeichnung
        {
            get { return _bezeichnung; }
            set { SetProperty(ref _bezeichnung, value, true); }
        }

        public Group Clone()
        {
            return new Group { Id = _id, Bezeichnung = _bezeichnung };
        }

        public void CopyFrom(Group other)
        {
            Bezeichnung = other.Bezeichnung;
        }
    }
}
