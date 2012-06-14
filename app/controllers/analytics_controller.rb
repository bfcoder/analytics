class AnalyticsController < ApplicationController
  unloadable

  include Api::V1::Account
  include Api::V1::Course
  include Api::V1::User
  include AnalyticsPermissions

  def department
    return unless require_analytics_for_department
    @account_json = account_json(@account, @current_user, session, ['html_url'])

    if @filter
      # what filter options apply
      current_start_date, current_end_date = @department_analytics.dates_for_filter('current')
      completed_start_date, completed_end_date = @department_analytics.dates_for_filter('completed')
      @filters = [
        {
          :id => 'current',
          :label => t('filters.current', 'Current Courses'),
          :fragment => 'current',
          :url => analytics_department_current_path(:account_id => @account.id),
          :startDate => current_start_date,
          :endDate => current_end_date
        },
        {
          :id => 'completed',
          :label => t('filters.completed', 'Completed Courses'),
          :fragment => 'completed',
          :url => analytics_department_completed_path(:account_id => @account.id),
          :startDate => completed_start_date,
          :endDate => completed_end_date
        }
      ]

      # the crumb details and page title for the current filter
      case @filter
      when 'current'
        @filter_crumb_name = t 'crumb.current', "Current Courses"
        @filter_crumb_url = analytics_department_current_path :account_id => @account.id
        @title = t 'page_title.current', "Analytics: %{account} -- Current Courses", :account => @account.name
      when 'completed'
        @filter_crumb_name = t 'crumb.completed', "Completed Courses"
        @filter_crumb_url = analytics_department_completed_path :account_id => @account.id
        @title = t 'page_title.completed', "Analytics: %{account} -- Completed Courses", :account => @account.name
      end
    else
      # what terms are available
      @filters = @account.root_account.enrollment_terms.active.map do |term|
        start_date, end_date = @department_analytics.dates_for_term(term)
        {
          :id => term.id,
          :label => term.name,
          :fragment => "terms/#{term.id}",
          :url => analytics_department_term_path(:account_id => @account.id, :term_id => term.id),
          :startDate => start_date,
          :endDate => end_date
        }
      end

      # the crumb details and page title for the current term
      @filter_crumb_name = @term.name
      @filter_crumb_url = analytics_department_term_path :account_id => @account.id, :term_id => @term.id
      @title = t 'page_title.term', "Analytics: %{account} -- %{term}", :account => @account.name, :term => @term.name
    end
  end

  def course
    return unless require_analytics_for_course
    @course_json = course_json(@course, @current_user, session, ['html_url'], false)
    @course_json[:students] = students_json(@course_analytics)
    @start_date = @course_analytics.start_date
    @end_date = @course_analytics.end_date
  end

  def student_in_course
    return unless require_analytics_for_student_in_course
    @course_json = course_json(@course, @current_user, session, ['html_url'], false)
    @course_json[:analytics_url] = analytics_course_path(:course_id => @course.id)
    @course_json[:students] = students_json(@course_analytics)
    @start_date = @student_analytics.start_date
    @end_date = @student_analytics.end_date
  end

  private

  def students_json(analytics)
    students = analytics.students
    User.send(:preload_associations, students, :pseudonyms => :account)
    students.map{ |student| student_json(student) }
  end

  def student_json(student)
    json = user_json(student, @current_user, session, ['avatar_url'], @course)
    json[:current_score] = student.computed_current_score
    json[:html_url] = polymorphic_url [@course, student]
    json[:analytics_url] = analytics_student_in_course_path(:course_id => @course.id, :student_id => student.id)
    json[:message_student_url] = conversations_path(:user_id => student.id)
    json
  end
end
