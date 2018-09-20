/**
 * Error
 * -----------------
 * 404 : Page or file not found
 *
 *
 * EISDIR: Directory error
 */
var GError;

GError = class GError extends Error {
  /**
   * Error
   * @param  {number|string} code - error code
   * @param  {string} message - error message
   */
  constructor(code, message) {
    super(message);
    this.code = code;
  }

};

module.exports = GError;
