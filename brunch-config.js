exports.config = {
  sourceMaps: false,
  production: true,

  modules: {
    definition: false,
    // wrapper: function(path, code){
    //   return "(function(exports){\n" + code + "\n})(typeof(exports) === \"undefined\" ? window.Drab = window.Drab || {} : exports);\n";
    // }
    wrapper: false,
  },

  files: {
    javascripts: {
      joinTo: 'drab.js'
    },
  },

  paths: {
    // Which directories to watch
    watched: ["web/static", "test/static"],

    // Where to compile files to
    public: "priv/static"
  },

  // Configure your plugins
  plugins: {
    babel: {
      // Do not use ES6 compiler in vendor code
      ignore: [/^(web\/static\/vendor)/]
    }
  }
};
