define [
  'jquery'
  'underscore'
  'Backbone'
  'analytics/jst/student_in_course'
  'analytics/compiled/graphs/page_views'
  'analytics/compiled/graphs/responsiveness'
  'analytics/compiled/graphs/assignment_tardiness'
  'analytics/compiled/graphs/grades'
  'analytics/compiled/graphs/colors'
  'compiled/widget/ComboBox'
], ($, _, Backbone, template, PageViews, Responsiveness, AssignmentTardiness, Grades, colors, ComboBox) ->

  class StudentInCourseView extends Backbone.View
    initialize: ->
      course = @model.get('course')
      student = @model.get('student')
      students = course.get('students')

      # build view
      @$el = $ template
        student: student.toJSON()
        course: course.toJSON()

      # cache elements for updates
      @$avatar = @$('.avatar')
      @$student_link = @$('.student_link')
      @$current_score = @$('.current_score')

      if students.length > 1
        # build combobox of student names to replace name element
        @comboBox = new ComboBox students.models,
          value: (student) -> student.get 'id'
          label: (student) -> student.get 'name'
          selected: student.get 'id'
        @$('.students_box').html @comboBox.$el

        # drive data from combobox (reverse connection in render)
        @comboBox.on 'change', (student) =>
          @model.set student: student

      # setup the graph objects
      @setupGraphs()

      # render now and any time the model changes
      @render()
      @model.on 'change:student', @render

    ##
    # TODO: I18n
    render: =>
      student = @model.get 'student'

      @$avatar.attr src: student.get 'avatar_url'
      @$student_link.text student.get 'name'
      @$student_link.attr href: student.get 'html_url'

      # hide message link unless url is present
      if message_url = student.get('message_student_url')
        @$('.message_student_link').show()
        @$('.message_student_link').attr href: message_url
      else
        @$('.message_student_link').hide()

      if current_score = student.get 'current_score'
        @$current_score.text "#{current_score}%"
      else
        @$current_score.text 'N/A'

      if @comboBox?
        @comboBox.select student.get 'id'

      participation = student.get('participation')
      messaging = student.get('messaging')
      assignments = student.get('assignments')

      @pageViews.graph participation
      @responsiveness.graph messaging
      @assignmentTardiness.graph assignments
      @grades.graph assignments

    ##
    # Instantiate the graphs.
    setupGraphs: ->
      # setup the graphs
      graphOpts =
        width: 800
        height: 100
        frameColor: colors.frame
        gridColor: colors.grid
        topMargin: 15
        verticalMargin: 15
        horizontalMargin: 40

      dateGraphOpts = $.extend {}, graphOpts,
        startDate: @options.startDate
        endDate: @options.endDate
        leftPadding: 30  # larger padding on left because of assymetrical
        rightPadding: 15 # responsiveness bubbles

      @pageViews = new PageViews @$("#participating-graph"), $.extend {}, dateGraphOpts,
        verticalPadding: 9
        barColor: colors.blue
        participationColor: colors.orange

      @responsiveness = new Responsiveness @$("#responsiveness-graph"), $.extend {}, dateGraphOpts,
        verticalPadding: 14
        gutterHeight: 22
        markerWidth: 31
        caratOffset: 7
        caratSize: 10
        studentColor: colors.orange
        instructorColor: colors.blue

      @assignmentTardiness = new AssignmentTardiness @$("#assignment-finishing-graph"), $.extend {}, dateGraphOpts,
        verticalPadding: 10
        barColorOnTime: colors.lightgreen
        diamondColorOnTime: colors.darkgreen
        barColorLate: colors.lightyellow
        diamondColorLate: colors.darkyellow
        diamondColorMissing: colors.darkred
        diamondColorUndated: colors.frame

      @grades = new Grades @$("#grades-graph"), $.extend {}, graphOpts,
        height: 200
        padding: 15
        whiskerColor: colors.frame
        boxColor: colors.grid
        medianColor: colors.frame
        goodRingColor: colors.lightgreen
        goodCenterColor: colors.darkgreen
        fairRingColor: colors.lightyellow
        fairCenterColor: colors.darkyellow
        poorRingColor: colors.lightred
        poorCenterColor: colors.darkred
