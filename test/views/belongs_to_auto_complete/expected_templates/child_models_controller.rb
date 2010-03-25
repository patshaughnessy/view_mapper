class ChildModelsController < ApplicationController

  auto_complete_for :parent_model, :name
  auto_complete_for :second_parent_model, :other_field

  # GET /child_models
  # GET /child_models.xml
  def index
    @child_models = ChildModel.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @child_models }
    end
  end

  # GET /child_models/1
  # GET /child_models/1.xml
  def show
    @child_model = ChildModel.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @child_model }
    end
  end

  # GET /child_models/new
  # GET /child_models/new.xml
  def new
    @child_model = ChildModel.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @child_model }
    end
  end

  # GET /child_models/1/edit
  def edit
    @child_model = ChildModel.find(params[:id])
  end

  # POST /child_models
  # POST /child_models.xml
  def create
    @child_model = ChildModel.new(params[:child_model])

    respond_to do |format|
      if @child_model.save
        flash[:notice] = 'ChildModel was successfully created.'
        format.html { redirect_to(@child_model) }
        format.xml  { render :xml => @child_model, :status => :created, :location => @child_model }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @child_model.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /child_models/1
  # PUT /child_models/1.xml
  def update
    @child_model = ChildModel.find(params[:id])

    respond_to do |format|
      if @child_model.update_attributes(params[:child_model])
        flash[:notice] = 'ChildModel was successfully updated.'
        format.html { redirect_to(@child_model) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @child_model.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /child_models/1
  # DELETE /child_models/1.xml
  def destroy
    @child_model = ChildModel.find(params[:id])
    @child_model.destroy

    respond_to do |format|
      format.html { redirect_to(child_models_url) }
      format.xml  { head :ok }
    end
  end
end
