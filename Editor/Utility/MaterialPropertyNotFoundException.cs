using System;

namespace com.kacper119p.CelShading.Editor.Utility
{
    /// <summary>
    /// Exception is thrown when property with given name couldn't be found on given material.
    /// </summary>
    public class MaterialPropertyNotFoundException : Exception
    {
        /// <summary>
        /// Initializes a new instance of the <see cref="MaterialPropertyNotFoundException"/> class.
        /// </summary>
        public MaterialPropertyNotFoundException() : base()
        {
        }

        /// <summary>
        /// Initializes a new instance of the <see cref="MaterialPropertyNotFoundException"/>
        /// class with a specified error message.
        /// </summary>
        /// <param name="message">The message that describes the error.</param>
        public MaterialPropertyNotFoundException(string message) : base(message)
        {
        }

        /// <summary>
        /// Initializes a new instance of the <see cref="MaterialPropertyNotFoundException"/>
        /// class with a specified error message and a reference to the inner exception that is the cause of this exception.
        /// </summary>
        /// <param name="message">The message that describes the error.</param>
        /// <param name="innerException">The exception that is the cause of the current exception, or a null reference.</param>
        public MaterialPropertyNotFoundException(string message, Exception innerException) : base(message,
        innerException)
        {
        }
    }
}
