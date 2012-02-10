(function() {

  if (typeof Spine === "undefined" || Spine === null) Spine = require('spine');

  Spine.Model.Session = {
    extended: function() {
      this.change(this.saveSession);
      return this.fetch(this.loadSession);
    },
    saveSession: function() {
      var result;
      result = JSON.stringify(this);
      return sessionStorage[this.className] = result;
    },
    loadSession: function() {
      var result;
      result = sessionStorage[this.className];
      return this.refresh(result || [], {
        clear: true
      });
    }
  };

  if (typeof module !== "undefined" && module !== null) {
    module.exports = Spine.Model.Session;
  }

}).call(this);
