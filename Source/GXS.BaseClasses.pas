//
// The graphics rendering engine GXScene  http://glscene.org
//
unit GXS.BaseClasses;

(* Base classes *)

interface

uses
  System.Classes,
  System.SysUtils,

  GXS.Strings,
  GXS.PersistentClasses;

type

  TProgressTimes = record
    deltaTime, newTime: Double
  end;

  (* Progression event for time-base animations/simulations.
     deltaTime is the time delta since last progress and newTime is the new
     time after the progress event is completed. *)
  TProgressEvent = procedure(Sender: TObject; const deltaTime, newTime: Double) of object;

  INotifyAble = interface(IInterface)
    ['{00079A6C-D46E-4126-86EE-F9E2951B4593}']
    procedure NotifyChange(Sender: TObject);
  end;

  IProgessAble = interface(IInterface)
    ['{95E44548-B0FE-4607-98D0-CA51169AF8B5}']
    procedure DoProgress(const progressTime: TProgressTimes);
  end;

  // An abstract class describing the "update" interface.
  TUpdateAbleObject = class(TInterfacedPersistent, INotifyAble)
  private
    FOwner: TPersistent;
    FUpdating: Integer;
    FOnNotifyChange: TNotifyEvent;
  protected
    function GetOwner: TPersistent; override; final;
  public
    constructor Create(AOwner: TPersistent); virtual;
    procedure NotifyChange(Sender: TObject); virtual;
    procedure Notification(Sender: TObject; Operation: TOperation); virtual;
    property Updating: Integer read FUpdating;
    procedure BeginUpdate;
    procedure EndUpdate;
    property Owner: TPersistent read FOwner;
    property OnNotifyChange: TNotifyEvent read FOnNotifyChange write FOnNotifyChange;
  end;

  // A base class describing the "cadenceing" interface.
  TCadenceAbleComponent = class(TComponent, IProgessAble)
  public
    procedure DoProgress(const progressTime: TProgressTimes); virtual;
  end;

  // A base class describing the "update" interface.
  TUpdateAbleComponent = class(TCadenceAbleComponent, INotifyAble)
  public
    procedure NotifyChange(Sender: TObject); virtual;
  end;

  TNotifyCollection = class(TOwnedCollection)
  strict private
    FOnNotifyChange: TNotifyEvent;
  strict protected
    procedure Update(item: TCollectionItem); override;
  public
    constructor Create(AOwner: TPersistent; AItemClass: TCollectionItemClass);
    property OnNotifyChange: TNotifyEvent read FOnNotifyChange write FOnNotifyChange;
  end;

//-------------------------------------------------------------------------
implementation
//-------------------------------------------------------------------------

//---------------------- TUpdateAbleObject -----------------------------------------

constructor TUpdateAbleObject.Create(AOwner: TPersistent);
begin
  inherited Create;
  FOwner := AOwner;
end;

procedure TUpdateAbleObject.NotifyChange(Sender: TObject);
begin
  if FUpdating = 0 then
  begin
    if Assigned(Owner) then
    begin
      if Owner is TUpdateAbleObject then
        TUpdateAbleObject(Owner).NotifyChange(Self)
      else if Owner is TUpdateAbleComponent then
        TUpdateAbleComponent(Owner).NotifyChange(Self);
    end;
    if Assigned(FOnNotifyChange) then
      FOnNotifyChange(Self);
  end;
end;

procedure TUpdateAbleObject.Notification(Sender: TObject; Operation: TOperation);
begin
end;

function TUpdateAbleObject.GetOwner: TPersistent;
begin
  Result := FOwner;
end;

procedure TUpdateAbleObject.BeginUpdate;
begin
  Inc(FUpdating);
end;

procedure TUpdateAbleObject.EndUpdate;
begin
  Dec(FUpdating);
  if FUpdating <= 0 then
  begin
    Assert(FUpdating = 0);
    NotifyChange(Self);
  end;
end;

// ------------------
// ------------------ TCadenceAbleComponent ------------------
// ------------------

procedure TCadenceAbleComponent.DoProgress(const progressTime: TProgressTimes);
begin
  // nothing
end;

// ------------------
// ------------------ TUpdateAbleObject ------------------
// ------------------

procedure TUpdateAbleComponent.NotifyChange(Sender: TObject);
begin
  if Assigned(Owner) then
    if (Owner is TUpdateAbleComponent) then
      (Owner as TUpdateAbleComponent).NotifyChange(Self);
end;

// ------------------
// ------------------ TNotifyCollection ------------------
// ------------------

constructor TNotifyCollection.Create(AOwner: TPersistent; AItemClass: TCollectionItemClass);
begin
  inherited Create(AOwner, AItemClass);
  if Assigned(AOwner) and (AOwner is TUpdateAbleComponent) then
    OnNotifyChange := TUpdateAbleComponent(AOwner).NotifyChange;
end;

procedure TNotifyCollection.Update(Item: TCollectionItem);
begin
  inherited;
  if Assigned(FOnNotifyChange) then
    FOnNotifyChange(Self);
end;

end.


