class ScenariosController < ApplicationController
  before_action :authenticate_admin_or_instructor
  before_action :set_user

  # Scenario
  before_action :set_scenario, only: [
    :clone, :destroyme, :edit, :modify, :show, :update, :save, :save_as,
    :boot, :boot_status, :unboot,
    :cloud_add, 
    :player_modify, :player_student_group_add, :player_add, :player_group_add, :player_delete, :player_group_admin_access_add, :player_group_user_access_add,
    :role_recipe_add, :role_add,
    :recipe_custom_add, :recipe_global_add, :recipe_global_get, :recipe_remove, :recipe_update, :recipe_update_view, :recipe_view,
    :group_add
  ]

  # Cloud
  before_action :set_cloud, only: [
    :boot_cloud, :unboot_cloud, :cloud_delete, :cloud_modify, :subnet_add
  ]

  # Subnet
  before_action :set_subnet, only: [
    :boot_subnet, :unboot_subnet, :subnet_delete, :subnet_modify, :instance_add
  ]

  # Instance
  before_action :set_instance, only: [
    :boot_instance, :unboot_instance, :instance_role_add, :instance_delete, :instance_bash_history, :instance_chef_error, :instance_modify
  ]

  # Group
  before_action :set_group, only: [
    :group_delete, :group_modify, :group_admin_access_add, :group_user_access_add, :group_player_add, :group_student_group_add, :group_student_group_remove
  ]
  before_action :set_instance_group, only: [
    :group_admin_access_remove, :group_user_access_remove
  ]
  before_action :set_player, only: [
    :group_player_delete
  ]

  # Role
  before_action :set_role, only: [
    :role_recipe_add, :role_delete, :role_modify
  ]
  before_action :set_recipe, only: [
    :recipe_remove, :recipe_update, :recipe_update_view, :recipe_update, :recipe_view
  ]
  before_action :set_role_recipe, only: [
    :role_recipe_remove
  ]
  before_action :set_instance_role, only: [
    :instance_role_remove
  ]

  # GET /scenarios
  # GET /scenarios.json
  def index
    @scenarios = []
    if @user.is_admin?
      @scenarios = Scenario.all
    else
      @scenarios = Scenario.where(user_id: current_user.id)
    end
  end

  # GET /scenarios/1
  # GET /scenarios/1.json
  def show
    # @clone = params[:clone]
    @scenario.check_status
  end

  # GET /scenarios/new
  def new
    @scenario = Scenario.new
    @templates = YmlRecord.yml_headers
    @templates_user = YmlRecord.yml_headers_user(@user)
    puts @templates
    puts
    puts @templates_user
  end

  # GET /scenarios/1/edit
  def edit
    @templates = []
  end

  # POST /scenarios
  # POST /scenarios.json
  def create
    # scrub this template input
    if template = scenario_params["template"]
      @scenario = YmlRecord.load_yml(scenario_params["template"], @user)
    else
      @scenario = Scenario.new(scenario_params)
    end

    respond_to do |format|
      if @scenario.save
        format.html { redirect_to @scenario, notice: 'Scenario was successfully created.' }
        format.json { render :show, status: :created, location: @scenario }
      else
        format.html { render :new }
        format.json { render json: @scenario.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /scenarios/1
  # PATCH/PUT /scenarios/1.json
  def update
    respond_to do |format|
      if @scenario.update(scenario_params)
        format.html { redirect_to @scenario, notice: 'Scenario was successfully updated.' }
        format.json { render :show, status: :ok, location: @scenario }
      else
        format.html { render :edit }
        format.json { render json: @scenario.errors, status: :unprocessable_entity }
      end
    end
  end

  def create_custom
    @scenario = Scenario.new(name: params[:name], custom: true, user_id: @user.id)
    if @scenario.make_custom
      @scenario.save
    end

    respond_to do |format|
      format.js { render "scenarios/js/scenario/create_custom.js.erb", layout: false }
    end
  end

  def obliterate_custom
    @filename = params[:filename]
    path = "#{Settings.app_path}/scenarios/user/#{@user.id}/#{params[:filename]}"
    if not File.exists? path
      @error = "does not exist."
    end
    FileUtils.rm_r path

    respond_to do |format|
      format.js { render "scenarios/js/scenario/obliterate_custom.js.erb", layout: false }
    end
  end

  def destroyme

    if not @scenario.custom?
      if @scenario.destroy
        respond_to do |format|
          format.js { render js: "window.location.pathname='/scenarios'" }
        end
      else
        respond_to do |format|
          format.js { render 'scenarios/js/scenario/destroy.js.erb', :layout => false }
        end
      end
    elsif params[:save] == nil and @scenario.modified?
      respond_to do |format|
        format.js { render 'scenarios/js/scenario/destroy.js.erb', :layout => false }
      end
    else
      if params[:save] == "true"
        @scenario.update_yml
      end
      if @scenario.destroy
        respond_to do |format|
          format.js { render js: "window.location.pathname='/scenarios'" }
        end
      else 
        respond_to do |format|
          format.js { render 'scenarios/js/scenario/destroy.js.erb', :layout => false }
        end
      end
    end

  end

  def save
    @scenario.update_yml
    respond_to do |format|
      format.js { render 'scenarios/js/scenario/save.js.erb', :layout => false }
    end
  end

  def save_as
    @scenario.change_name(params[:name])
    respond_to do |format|
      format.js { render 'scenarios/js/scenario/save_as.js.erb', :layout => false }
    end
  end

  def clone
    @clone = @scenario.clone(params[:name])
    respond_to do |format|
      format.js { render "scenarios/js/scenario/clone.js.erb", layout: false }
    end
  end

  def clone_set
    clone = Scenario.find(params[:clone_id])
    redirect_to clone, notice: 'Scenario was successfully cloned.'
  end

  #############################################################
  # BOOTING

  def boot
    @scenario.boot(dependents: true)
    respond_to do |format|
      format.js { render 'scenarios/js/boot/boot_scenario.js.erb', :layout => false }
    end
  end

  def unboot
    @scenario.unboot(dependents: true)
    respond_to do |format|
      format.js { render 'scenarios/js/boot/unboot_scenario.js.erb', :layout => false }
    end
  end

  def boot_cloud
    @cloud.boot(solo: true)
    respond_to  do |format|
      format.js { render template: 'scenarios/js/boot/boot_cloud.js.erb', layout: false }
    end
  end

  def unboot_cloud
    @cloud.unboot(solo: true)
    respond_to do |format|
      format.js { render template: 'scenarios/js/boot/unboot_cloud.js.erb',  layout: false }
    end
  end

  def boot_subnet
    @subnet.boot(solo: true)
    respond_to do |format|
      format.js { render template: 'scenarios/js/boot/boot_subnet.js.erb', layout: false }
    end
  end

  def unboot_subnet
    @subnet.unboot(solo: true)
    respond_to do |format|
      format.js { render template: 'scenarios/js/boot/unboot_subnet.js.erb', layout: false }
    end
  end

  def boot_instance
    @instance.boot(solo: true)
    respond_to do |format|
      format.js { render template: 'scenarios/js/boot/boot_instance.js.erb', layout: false }
    end
  end

  def unboot_instance
    @instance.unboot(solo: true)
    respond_to do |format|
      format.js { render template: 'scenarios/js/boot/unboot_instance.js.erb', layout: false }
    end
  end

  def boot_status
    @scenario.check_status
    respond_to do |format|
      format.js { render 'scenarios/js/boot/boot_status.js.erb', :layout => false }
    end
  end

  ###############################################################
  #  Resource Modification

  # CLOUD
  def cloud_add
    @cloud = @scenario.clouds.new(name: params[:name], cidr_block: params[:cidr_block])
    @cloud.save

    respond_to do |format|
      format.js { render template: 'scenarios/js/cloud/add.js.erb', layout: false }
    end
  end

  def cloud_delete
    @cloud.destroy
    respond_to do |format|
      format.js { render template: 'scenarios/js/cloud/delete.js.erb', layout: false }
    end
  end

  def cloud_modify
    @cloud.update(name: params[:name], cidr_block: params[:cidr_block])

    respond_to do |format|
      format.js { render template: 'scenarios/js/cloud/modify.js.erb', layout: false }
    end
  end

  # SUBNET
  def subnet_add
    @subnet = @cloud.subnets.new(name: params[:name], cidr_block: params[:cidr_block], internet_accessible: params[:internet_accessible])
    @subnet.save

    respond_to do |format|
      format.js { render template: 'scenarios/js/subnet/add.js.erb', layout: false }
    end
  end

  def subnet_delete
    @subnet.destroy
    respond_to do |format|
      format.js { render template: 'scenarios/js/subnet/delete.js.erb', layout: false }
    end
  end

  def subnet_modify
    @subnet.update(name: params[:name], cidr_block: params[:cidr_block], internet_accessible: params[:internet_accessible])

    respond_to do |format|
      format.js { render template: 'scenarios/js/subnet/modify.js.erb', layout: false }
    end
  end

  # INSTANCE
  def instance_add
    @instance = @subnet.instances.new(
      name: params[:name],
      ip_address: params[:ip],
      os: params[:os],
      internet_accessible: params[:internet_accessible],
      uuid: `uuidgen`.chomp
    )
    @instance.save

    respond_to do |format|
      format.js { render template: 'scenarios/js/instance/add.js.erb', layout: false }
    end
  end

  def instance_delete
    @instance.destroy
    respond_to do |format|
      format.js { render template: 'scenarios/js/instance/delete.js.erb', layout: false }
    end
  end

  def instance_modify
    @accessible_to_not_accessible = ((@instance.internet_accessible == true) and (params[:internet_accessible] == "false"))
    @not_accessible_to_accessible = ((@instance.internet_accessible == false) and (params[:internet_accessible] == "true"))

    @instance.update(
      name:  params[:name],
      ip_address:  params[:ip_address],
      internet_accessible:  params[:internet_accessible],
      os:  params[:os]
    )
    
    respond_to do |format|
      format.js { render template: 'scenarios/js/instance/modify.js.erb', layout: false }
    end
  end

  def instance_role_add
    @instance_role = @instance.role_add(params[:name])
    respond_to do |format|
      format.js { render template: 'scenarios/js/instance/role_add.js.erb', layout: false }
    end
  end

  def instance_role_remove
    @instance_role.destroy
    respond_to do |format|
      format.js { render template: 'scenarios/js/instance/role_remove.js.erb', layout: false }
    end
  end

  def instance_bash_history
    @bash_history = @instance.get_bash_history.gsub("\n", "<br>").html_safe;
    respond_to do |format|
      format.js { render template: 'scenarios/js/instance/bash_history.js.erb', layout: false }
    end
  end

  def instance_chef_error
    @chef_error = @instance.get_chef_error.gsub("\"", "\\\"").gsub(/\n/, "\\n").gsub(/\r/, "").html_safe
    respond_to do |format|
      format.js { render template: 'scenarios/js/instance/chef_error.js.erb', layout: false }
    end
  end

  ###############################################################
  #  Players

  def group_add
    @group = @scenario.groups.new(name: params[:name])
    @group.save
    respond_to do |format|
      format.js { render template: 'scenarios/js/group/add.js.erb', layout: false }
    end
  end

  def group_delete
    @group.destroy
    respond_to do |format|
      format.js { render template: 'scenarios/js/group/delete.js.erb', layout: false }
    end
  end

  def group_modify
    @group.update(name: params[:name])
    respond_to do |format|
      format.js { render template: 'scenarios/js/group/modify.js.erb', layout: false }
    end
  end

  def group_admin_access_add
    @instance = @group.scenario.instances.select { |i| i.name == params[:name] }.first
    if @instance
      @instance_group = @group.instance_groups.new(instance_id: @instance.id, administrator: true)
      @instance_group.save
    end
    respond_to do |format|
      format.js { render template: 'scenarios/js/group/admin_access_add.js.erb', layout: false }
    end
  end

  def group_admin_access_remove
    @instance_group.destroy
    respond_to do |format|
      format.js { render template: 'scenarios/js/group/admin_access_remove.js.erb', layout: false }
    end
  end

  def group_user_access_add
    @instance = @group.scenario.instances.select { |i| i.name == params[:name] }.first
    if @instance
      @instance_group = @group.instance_groups.new(instance_id: @instance.id, administrator: false)
      @instance_group.save
    end
    respond_to do |format|
      format.js { render template: 'scenarios/js/group/user_access_add.js.erb', layout: false }
    end
  end

  def group_user_access_remove
    @instance_group.destroy
    respond_to do |format|
      format.js { render template: 'scenarios/js/group/user_access_remove.js.erb', layout: false }
    end
  end

  def group_player_add
    @player = @group.players.new(login: params[:login], password: params[:password])
    @player.save

    respond_to do |format|
      format.js { render template: 'scenarios/js/group/player_add.js.erb', layout: false }
    end
  end

  def group_player_delete
    @player.destroy
    respond_to do |format|
      format.js { render template: 'scenarios/js/group/player_delete.js.erb', layout: false }
    end
  end

  def group_student_group_add
    @student_group_name = params[:name]
    @players = @group.student_group_add(params[:name])
    respond_to do |format|
      format.js { render template: 'scenarios/js/group/student_group_add.js.erb', layout: false }
    end
  end

  def group_student_group_remove
    @student_group_name = params[:name]
    @players = @group.student_group_remove(params[:name])
    puts @players
    respond_to do |format|
      format.js { render template: 'scenarios/js/group/student_group_remove.js.erb', layout: false }
    end
  end

  ###############################################################
  #  Roles

  def role_add
    @role = @scenario.roles.new(name: params[:name])
    @role.save
    respond_to do |format|
      format.js { render template: 'scenarios/js/role/add.js.erb', layout: false }
    end
  end

  def role_delete
    @instance_role_ids = @role.instance_roles.map { |ir| ir.id }
    @role.destroy
    respond_to do |format|
      format.js { render template: 'scenarios/js/role/delete.js.erb', layout: false }
    end
  end

  def role_modify
    @role.update(name: params[:name])
    respond_to do |format|
      format.js { render template: 'scenarios/js/role/modify.js.erb', layout: false }
    end
  end

  def role_recipe_add
    @recipe = @scenario.recipes.find_by_name(params[:name])
    if @recipe
      @role_recipe = @role.role_recipes.new(recipe_id: @recipe.id)
      @role_recipe.save
    end
    respond_to do |format|
      format.js { render template: 'scenarios/js/role/recipe_add.js.erb', layout: false }
    end
  end

  def role_recipe_remove
    @role_recipe.destroy
    respond_to do |format|
      format.js { render template: 'scenarios/js/role/recipe_remove.js.erb', layout: false }
    end
  end

  ###############################################################
  #  Recipes

  def recipe_custom_add
    # @scenario.recipe_custom_add(params[:recipe], params[:text])

    @recipe = @scenario.recipes.new(name: params[:name], custom: true)
    if @recipe and not @recipe.errors.any?
      @recipe.text_update(params[:text])
      @recipe.save
    end

    respond_to do |format|
      format.js { render template: 'scenarios/js/recipe/custom_add.js.erb', layout: false }
    end
  end

  def recipe_global_add
    @recipe = @scenario.recipes.new(name: params[:name], custom: false)
    @recipe.save
    respond_to do |format|
      format.js { render template: 'scenarios/js/recipe/global_add.js.erb', layout: false }
    end
  end

  def recipe_global_get
    @recipes = @scenario.get_global_recipes_and_descriptions
    respond_to do |format|
      format.js { render template: 'scenarios/js/recipe/global_get.js.erb', layout: false }
    end
  end

  def recipe_remove
    @role_recipes_ids = @recipe.role_recipes.map { |rr| rr.id }
    @recipe.destroy
    respond_to do |format|
      format.js { render template: 'scenarios/js/recipe/remove.js.erb', layout: false }
    end
  end

  def recipe_update
    @recipe.text_update(params[:text])
    respond_to do |format|
      format.js { render template: 'scenarios/js/recipe/update.js.erb', layout: false }
    end
  end

  def recipe_update_view
    if not @recipe.custom
      @error = "This is a global recipe can not update from here."
    else
      @recipe_text = @recipe.text.gsub("\"", "\\\"").gsub(/\n/, "\\n").gsub(/\r/, "").html_safe;
    end
    respond_to do |format|
      format.js { render template: 'scenarios/js/recipe/update_view.js.erb', layout: false }
    end
  end

  def recipe_view
    @recipe_text = @recipe.text.gsub("\n", "<br>").gsub(" ", "&nbsp").gsub("'", "\"").gsub(/\r/, "").html_safe;
    respond_to do |format|
      format.js { render template: 'scenarios/js/recipe/view.js.erb', layout: false }
    end
  end

  ###############################################################
  #  Helpers

  def log_get
    if params[:kind] == 'scenario'
      resource = Scenario.find(params[:id])
      @dropdown = "dropdown-scenario"
    elsif params[:kind] == 'cloud'
      resource = Cloud.find(params[:id])
      @dropdown = "cloud-#{resource.id}-dropdown"
    elsif params[:kind] == 'subnet'
      resource = Subnet.find(params[:id])
      @dropdown = "subnet-#{resource.id}-dropdown"
    elsif params[:kind] == 'instance'
      resource = Instance.find(params[:id])
      @dropdown = "instance-#{resource.id}-dropdown"
    end

    if not @user.owns? resource
      head :ok, content_type: "text/html"
      return
    end

    @htmllog = resource.log.gsub("\n", "<br>").html_safe;
    @name = resource.name

    respond_to do |format|
      format.js { render template: 'scenarios/js/log.js.erb', layout: false }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_user
      @user = User.find(current_user.id)
    end

    def set_scenario
      @scenario = Scenario.find(params[:id])
      if not @user.owns? @scenario
        head :ok, content_type: "text/html"
        return
      end
    end

    def set_cloud
      @cloud = Cloud.find(params[:cloud_id])
      if not @user.owns? @cloud
        head :ok, content_type: "text/html"
        return
      end
    end

    def set_subnet
      @subnet = Subnet.find(params[:subnet_id])
      if not @user.owns? @subnet
        head :ok, content_type: "text/html"
        return
      end
    end

    def set_instance
      @instance = Instance.find(params[:instance_id])
      if not @user.owns? @instance
        head :ok, content_type: "text/html"
        return
      end
    end

    def set_group
      @group = Group.find(params[:group_id])
      if not @user.owns? @group
        head :ok, content_type: "text/html"
        return
      end
    end

    def set_instance_role
      @instance_role = InstanceRole.find(params[:instance_role_id])
      if not @user.owns? @instance_role
        head :ok, content_type: "text/html"
        return
      end
    end

    def set_role
      @role = Role.find(params[:role_id])
      if not @user.owns? @role
        head :ok, content_type: "text/html"
        return
      end
    end

    def set_role_recipe
      @role_recipe = RoleRecipe.find(params[:role_recipe_id])
      if not @user.owns? @role_recipe
        head :ok, content_type: "text/html"
        return
      end
    end

    def set_recipe
      @recipe = Recipe.find(params[:recipe_id])
      if not @user.owns? @recipe
        head :ok, content_type: "text/html"
        return
      end
    end

    def set_player
      @player = Player.find(params[:player_id])
      if not @user.owns? @player
        head :ok, content_type: "text/html"
        return
      end
    end

    def set_instance_group
      @instance_group = InstanceGroup.find(params[:instance_group_id])
      if not @user.owns? @instance_group
        head :ok, content_type: "text/html"
        return
      end
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def scenario_params
      params.require(:scenario).permit(:game_type, :name, :template)
    end
end
