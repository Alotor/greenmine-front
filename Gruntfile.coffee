module.exports = (grunt) ->
    externalSources = [
        'app/js/jquery.js'
        'app/js/ui/jquery.ui.core.js'
        'app/js/ui/jquery.ui.position.js'
        'app/js/ui/jquery.ui.widget.js',
        'app/js/ui/jquery.ui.mouse.js',
        'app/js/ui/jquery.ui.draggable.js',
        'app/js/ui/jquery.ui.droppable.js',
        'app/js/ui/jquery.ui.effect.js',
        'app/js/ui/jquery.ui.effect-drop.js',
        'app/js/ui/jquery.ui.effect-transfer.js',
        'app/js/ui/jquery.ui.position.js',
        'app/js/ui/jquery.ui.sortable.js',
        'app/js/jquery.markitup.js',
        'app/js/select2.js',
        'app/js/markdown.js',
        'app/js/lodash.js',
        'app/js/underscore.string.js',
        'app/js/angular.js',
        'app/js/bootstrap.js',
        'app/js/moment.js',
        'app/js/kalendae.js',
        'app/js/parsley.js',
        'app/js/checksley.js',
        'app/js/q.js',
        'app/js/sha1.js',
        'app/js/Chart.js'
    ]

    grunt.initConfig({
        pkg: grunt.file.readJSON('package.json'),

        less: {
            dist: {
                options: {
                    paths: ["app/less"],
                    yuicompress: true
                },
                files: {
                    "app/less/style.css": "app/less/greenmine-main.less"
                }
            }
        },

        uglify: {
            options: {
                banner: '/*! <%= pkg.name %> <%= grunt.template.today("yyyy-mm-dd") %> */\n',
                mangle: false,
                report: 'min'
            },

            libs: {
                dest: "app/dist/libs.js",
                src: externalSources
            },

            app: {
                dest: "app/dist/app.js",
                src: ["app/dist/_app.js"]
            }
        },

        coffee: {
            mainDevelopment: {
                options: {join: false},
                files: {
                    "app/dist/app.js": [
                        "app/coffee/**/*.coffee"
                        "app/coffee/*.coffee"
                    ]
                }
            },

            mainProduction: {
                options: {join: false},
                files: {"app/dist/_app.js": ["app/coffee/**/*.coffee"]}
            }
        },

        concat: {
            options: {
                separator: ';',
                banner: '/*! <%= pkg.name %> - v<%= pkg.version %> - ' +
                        '<%= grunt.template.today("yyyy-mm-dd") %> */\n'
            },

            libs: {
                dest: "app/dist/libs.js",
                src: externalSources
            }
        },

        watch: {
            less: {
                files: ['app/less/**/*.less'],
                tasks: ['less']
            },

            coffeeMain: {
                files: ['app/coffee/**/*.coffee'],
                tasks: ['coffee:mainDevelopment']
            },

            libs: {
                files: externalSources,
                tasks: ["concat"],
            }
        },

        connect: {
            devserver: {
                options: {
                    port: 9001,
                    base: 'app'
                }
            },

            proserver: {
                options: {
                    port: 9001,
                    base: 'app',
                    keepalive: true
                }
            }
        },

        htmlmin: {
            dist: {
                options: {
                    removeComments: true,
                    collapseWhitespace: true
                },
                files: {
                    'app/index.html': 'app/index.template.html'
                }
            }
        },
    })

    grunt.loadNpmTasks('grunt-contrib-uglify')
    grunt.loadNpmTasks('grunt-contrib-concat')
    grunt.loadNpmTasks('grunt-contrib-less')
    grunt.loadNpmTasks('grunt-contrib-watch')
    grunt.loadNpmTasks('grunt-contrib-connect')
    grunt.loadNpmTasks('grunt-contrib-jshint')
    grunt.loadNpmTasks('grunt-contrib-htmlmin')
    grunt.loadNpmTasks('grunt-contrib-coffee')

    grunt.registerTask('production', [
        'less',
        'coffee:mainProduction',
        'uglify',
        'htmlmin',
    ])

    grunt.registerTask('development', [
        'less',
        'coffee:mainDevelopment',
        'concat:libs',
        'htmlmin',
    ])

    grunt.registerTask('default', [
        'development',
        'connect:devserver',
        'watch'
    ])
