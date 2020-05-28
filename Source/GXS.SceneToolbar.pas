//
// The unit for GXScene Engine
//
{
  Added a toolbar to Delphi IDE. 
  
}

unit GXS.SceneToolbar;

interface

implementation

uses
  System.Classes,
  System.SysUtils,
  FMX.Graphics,
  FMX.ImgList,
  FMX.Controls,
  FMX.ComCtrls,
  FMX.ExtCtrls,
  FMX.ActnList,

  ToolsAPI,

  GXS.Scene,
  GXS.Generics;

const
  cGXSceneViewerToolbar = 'GXSceneViewerToolbar';

type

  TgxSToolButtonReceiver = class
  protected
    FActionList: GList<TBasicAction>;
    procedure OnClick(Sender: TObject);
  public
    constructor Create;
    destructor Destroy; override;
  end;

var
  vReciver: TgxSToolButtonReceiver;

function MsgServices: IOTAMessageServices;
  begin
    Result := (BorlandIDEServices as IOTAMessageServices);
    Assert(Result <> nil, 'IOTAMessageServices not available');
  end;

procedure AddGLSceneToolbar;

  var
    Services: INTAServices;
    T: Integer;
    GLToolbar: TToolBar;

    procedure AddButton(const AHint, AResName: string);
      var
        Bmp: TBitmap;
        Act: TAction;
      begin
        Act := TAction.Create(nil);
        Act.ActionList := Services.ActionList;
        vReciver.FActionList.Add(Act);

        Bmp := TBitmap.Create;
        Bmp.LoadFromResourceName(HInstance, AResName);
        Act.ImageIndex := Services.AddMasked(Bmp, Bmp.TransparentColor, 'GLScene.' + AResName);
        Bmp.Destroy;

        Act.Hint := AHint;
        Act.Tag := T;
        Act.OnExecute := vReciver.OnClick;

        with Services.AddToolButton(cGXSceneViewerToolbar, 'GLSButton' + IntToStr(T), Act) do
          Action := Act;
        Act.Enabled := True;

        Inc(T);
      end;

  begin

    if not Supports(BorlandIDEServices, INTAServices, Services) then
      exit;

    GLToolbar := Services.ToolBar[cGXSceneViewerToolbar];
    vReciver := TgxSToolButtonReceiver.Create;
    T := 0;

    if not Assigned(GLToolbar) then
    begin
      GLToolbar := Services.NewToolbar(cGXSceneViewerToolbar, 'GXScene Viewer Control');
      if Assigned(GLToolbar) then
        with GLToolbar do
        begin
          AddButton('GXSceneViewer default control mode', 'GXSceneViewerControlToolbarDefault');
          AddButton('GXSceneViewer navigation mode', 'GXSceneViewerControlToolbarNavigation');
          AddButton('GXSceneViewer gizmo mode', 'GXSceneViewerControlToolbarGizmo');
          AddButton('Reset view to GXSceneViewer camera', 'GXSceneViewerControlToolbarCameraReset');
          Visible := True;
        end;
      MsgServices.AddTitleMessage('GXScene Toolbar created');
    end
    else
    begin
      for T := 0 to GLToolbar.ButtonCount - 1 do
      begin
        GLToolbar.Buttons[T].Action.OnExecute := vReciver.OnClick;
        vReciver.FActionList.Add(GLToolbar.Buttons[T].Action);
      end;
      MsgServices.AddTitleMessage('GXScene Toolbar activated');
    end;
    Services.ToolbarModified(GLToolbar);
  end;

constructor TgxSToolButtonReceiver.Create;
begin
  FActionList := GList<TBasicAction>.Create;
  vGXSceneViewerMode := svmDefault;
end;

destructor TgxSToolButtonReceiver.Destroy;
var
  I: Integer;
begin
  for I := 0 to FActionList.Count - 1 do
    FActionList[I].OnExecute := nil;
  FActionList.Destroy;
  vGXSceneViewerMode := svmDisabled;
end;

procedure TgxSToolButtonReceiver.OnClick(Sender: TObject);
  const
    cMode: array [TgxSceneViewerMode] of string = ('', 'default', 'navigation', 'gizmo');
  var
    T: Integer;
  begin
    inherited;
    T := TComponent(Sender).Tag;
    if T < 3 then
    begin
      vGXSceneViewerMode := TgxSceneViewerMode(T+1);
      MsgServices.AddTitleMessage(Format('GXSceneViewer %s mode', [cMode[vGXSceneViewerMode]]));
    end
    else
      vResetDesignView := True;
  end;

initialization

  AddGLSceneToolbar;

finalization

  vReciver.Free;

end.
