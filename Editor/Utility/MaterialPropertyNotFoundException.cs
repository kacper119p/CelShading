using System;
using System.Runtime.Serialization;

namespace com.kacper119p.CelShading.Editor.Utility
{
    public class MaterialPropertyNotFoundException : Exception
    {
        public MaterialPropertyNotFoundException() : base()
        {
        }
        
        public MaterialPropertyNotFoundException(SerializationInfo info , StreamingContext context) : base(info, context)
        {
        }
        
        public MaterialPropertyNotFoundException(string message) : base(message)
        {
        }

        public MaterialPropertyNotFoundException(string message, Exception innerException) : base(message,
        innerException)
        {
        }
    }
}
