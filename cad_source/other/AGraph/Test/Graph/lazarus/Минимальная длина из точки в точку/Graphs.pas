{ Version 050625. Copyright � Alexey A.Chernobaev, 1996-2005 }

unit Graphs;
{
  ��������-��������������� ���������� ��� ������ � ����������������� �������.

  Object-oriented library for processing graphs with attributes.
}

interface

{$I VCheck.inc}

uses
  SysUtils, ExtType, ExtSys, Vectors, AttrType, AttrMap, AttrSet, Aliasv, Aliasm,
  Boolv, Boolm, Int8v, Int16v, Int16g, Int16m, UInt16v, Int32v, Int64v, F32v, F64v,
  F80v, F32m, F64m, F80m, Pointerv, MultiLst, IStack, PStack, PQueue, F_PQueue,
  VStream, VectErr, AttrErr, GraphErr;

type
  TGraphObjectState = (gsDestroying, gsValidConnected, gsValidSeparates,
    gsValidRingEdges);
  { gsDestroying: ������ ��������� � ��������� ����������� (����������� ���
    ����� Destroy);
    gsValidConnected: ���������� � ��������� (TGraph.FConnected) �����
    (��������� ���������� ������ ��� ������);
    gsValidSeparates: ���������� � ����������� ��������� (TVertex.SeparateIndex
    � TGraph.SeparateCount) ����� (��������� ���������� ������ ��� ������);
    gsValidRingEdges: ���������� � ���� ����� (��������� / ������������) �����;
    (���������� ������ ��� ������; ����� ����� ������ ��� gsValidConnected) }

  TGraphObjectStates = set of TGraphObjectState;

  TTempVar = packed record
    case Byte of
      0: (AsInt32: Int32);
      1: (AsPointer: Pointer);
  end;

  TGraph = class;

  TGraphObject = class(TAttrSet)
  protected
    FIndex: Integer;
    FStates: TGraphObjectStates;
    FTemp: TTempVar; { ������������ ���������� ����������� }
  public
    procedure WriteToStream(VStream: TVStream); override;
    procedure ReadFromStream(VStream: TVStream); override;
    procedure Assign(Source: TVector); override;

    property Temp: TTempVar read FTemp;
  end;

  TGraphElement = class(TGraphObject)
  protected
    FLocal: TAutoAttrSet;
    FGraph: TGraph;
  public
    destructor Destroy; override;

    class function Compare(Element1, Element2: Pointer): Integer;
    { ���������� ���������� �������� ��������� �����, �, ���� ����������
      �������� �����, ���������� ��������� �������� (��������, ������������
      � ��������, ������� ���� ������ '.', �� ��������� � ���������) }

    procedure WriteToStream(VStream: TVStream); override;
    procedure ReadFromStream(VStream: TVStream); override;
    procedure Assign(Source: TVector); override;
    procedure Pack; override;

    function HasLocal: Bool;
    function Local: TAttrSet;
    { ����� ��������� ��������� �������� }

    property Graph: TGraph read FGraph;
    { ����, �������� ����������� ������ ������� }
  end;

  TEdge = class;
  TVertex = class;

  TVertex = class(TGraphElement)
  protected
    NeighbEdges: TClassList;
    function GetNeighbour(I: Integer): TVertex;
    function GetIncidentEdge(I: Integer): TEdge; {$IFDEF V_INLINE}inline;{$ENDIF}

    { *** ������� (directed graphs) }

    function GetInNeighbour(I: Integer): TVertex;
    function GetOutNeighbour(I: Integer): TVertex;
    function GetInArc(I: Integer): TEdge;
    function GetOutArc(I: Integer): TEdge;

    { *** ������� }

    function GetParent: TVertex;
    procedure SafeSetParent(Value: TVertex);
    procedure SetParent(Value: TVertex);
    function GetChild(I: Integer): TVertex;
    function GetIsRoot: Bool;
    procedure SetIsRoot(Value: Bool);

    { *** ������������ ���� }

    function GetIsSource: Bool;
    procedure SetIsSource(Value: Bool);
    function GetIsSink: Bool;
    procedure SetIsSink(Value: Bool);

    { *** �������������� ����� }

    function GetX: Float; {$IFDEF V_INLINE}inline;{$ENDIF}
    procedure SetX(Value: Float); {$IFDEF V_INLINE}inline;{$ENDIF}
    function GetY: Float; {$IFDEF V_INLINE}inline;{$ENDIF}
    procedure SetY(Value: Float); {$IFDEF V_INLINE}inline;{$ENDIF}
    function GetZ: Float; {$IFDEF V_INLINE}inline;{$ENDIF}
    procedure SetZ(Value: Float); {$IFDEF V_INLINE}inline;{$ENDIF}
  public
    constructor Create(AGraph: TGraph);
    destructor Destroy; override;
    procedure Pack; override;

    property Index: Integer read FIndex;
    { ����� ������� ����� ������ ����� (0..Graph.VertexCount-1) }
    {$IFDEF V_ALLOW_DEPRECATE}
    property IndexInGraph: Integer read FIndex; { ��������! }
    {$ENDIF}
    function Degree: Integer; {$IFDEF V_INLINE}inline;{$ENDIF}
    { ������� ������� ����� }
    property Neighbour[I: Integer]: TVertex read GetNeighbour;
    { �������� ��� ������ ������� ����� [0..Degree-1] }
    property IncidentVertex[I: Integer]: TVertex read GetNeighbour;
    { ������� Neighbour }
    {$IFDEF V_ALLOW_DEPRECATE}
    property Neighbours[I: Integer]: TVertex read GetNeighbour; { ��������! }
    property IncidentVertices[I: Integer]: TVertex read GetNeighbour; { ��������! }
    {$ENDIF}
    property IncidentEdge[I: Integer]: TEdge read GetIncidentEdge;
    { ����������� (��������) ��� ������ ������� ����� [0..Degree-1] }
    function SeparateIndex: Integer;
    { ����� ���������� ���������, ������� ����������� �������
      (0..Graph.SeparateCount-1) }
    function RingVertex: Bool;
    { �������� �� ������� ���������, �.�. ���� ������� ���������� ���� �� ����
      ��������� ����� (������� �����) }
    procedure SortIncidentEdges(CompareEdges: TCompareFunc);
    { ������������� ����������� ����� ����� �� ����������� �������� CompareEdges }
    procedure SortIncidentEdgesByObject(CompareEdges: TCompareEvent);
    { ������������� ����������� ����� ����� �� ����������� �������� CompareEdges }
    property TimeMark: Int32 read FTemp.AsInt32;
    { �������'�� ����� �������; �������� ���������� ������ ��������������� �����
      ������ ������ DFSFromVertex ��� ������� ��������� BFSFromVertexXXXX;
      ������ ������ ����� �������� ��� �������� ������������ ������� }

    { *** ������� }

    function InDegree: Integer;
    { ����������� ������ ������� (���������� �������� � ������� ���) }
    function OutDegree: Integer;
    { ����������� ������ ������� (���������� ��������� �� ������� ���) }
    procedure GetInOutDegree(var VertexInDegree, VertexOutDegree: Integer);
    { ���������� ����� InDegree � OutDegree }
    property OutNeighbour[I: Integer]: TVertex read GetOutNeighbour;
    { ������� �����, � ������� �� ������ ������� ������� ���� [0..OutDegree-1] }
    property InNeighbour[I: Integer]: TVertex read GetInNeighbour;
    { ������� �����, �� ������� � ������ ������� ������ ���� [0..InDegree-1] }
    property OutArc[I: Integer]: TEdge read GetOutArc;
    { ��������� �� ������� ���� [0..OutDegree-1] }
    property InArc[I: Integer]: TEdge read GetInArc;
    { �������� � ������� ���� [0..InDegree-1] }

    { *** ������� }

    function AddChild: TVertex;
    { ��������� �������-������� }
    property Parent: TVertex read GetParent write SetParent;
    { �������, ������������ ��� ������ (nil ��� ����� ��� ������. �������) -
      ������ ��������� � Neighbour[0], ������� ����� ��������� Parent �������
      ������� ����� ����������; ����� ����, ���� ������� �� ���� �������������,
      �� ��� ��������� Parent ����� �� ������ ��������� ������������ }
    function ChildCount: Integer;
    { ���������� ���������� ��������; ��� ������� 0, ��� ������������� ������ -1 }
    property Childs[I: Integer]: TVertex read GetChild;
    { ������� ������� [0..ChildCount-1] }
    property IsRoot: Bool read GetIsRoot write SetIsRoot;
    { ��������� True, ���� ������ ������� �������� ������ ������, ����� - False }
    function IsAncestorOf(V: TVertex): Bool;
    { ���������� True, ���� ������ ������� ��������� � V ��� �������� �������
      ������� V }
    procedure SortChilds(CompareVertices: TCompareEvent);
    { ����������� �������-������� � ������������ � CompareVertices }

    { *** ������������ ���� }

    property IsNetworkSource: Bool read GetIsSource write SetIsSource;
    { ������� �������� ������� }
    property IsNetworkSink: Bool read GetIsSink write SetIsSink;
    { ������� �������� ������ }

    { *** �������������� ����� }

    property X: Float read GetX write SetX;
    { X-���������� }
    property Y: Float read GetY write SetY;
    { Y-���������� }
    property Z: Float read GetZ write SetZ;
    { Z-���������� }
  end;

  TEdge = class(TGraphElement)
  protected
    FV1, FV2: TVertex;
    { ����� ����� }
    function RemoveFromNeighbEdges(V: TVertex): Integer;
    { ������������ ��� �������� / ������� ����� }
    function Hidden: Bool;
    { ���������, �������� �� ����� "�������" }

    { *** ������������ ���� }

    function GetMaxFlow: Float;
    procedure SetMaxFlow(Value: Float);
    function GetFlow: Float;
    procedure SetFlow(Value: Float);

    { *** ���������� ����� (weighted graphs) }

    function GetWeight: Float; {$IFDEF V_INLINE}inline;{$ENDIF}
    procedure SetWeight(Value: Float); {$IFDEF V_INLINE}inline;{$ENDIF}
  public
    constructor Create(AGraph: TGraph; FromVertex, ToVertex: TVertex);
    destructor Destroy; override;

    property Index: Integer read FIndex;
    { ����� ����� ����� ����� ����� (0..Graph.EdgeCount-1) }
    {$IFDEF V_ALLOW_DEPRECATE}
    property IndexInGraph: Integer read FIndex; { ��������! }
    {$ENDIF}
    property V1: TVertex read FV1;
    { ������ ����� ����� (������ ���� � �������) }
    property V2: TVertex read FV2;
    { ������ ����� ����� (����� ���� � �������) }
    function EdgeVertices(Vertex1, Vertex2: TVertex): Bool;
    { ���������, �������� �� ������� Vertex1 � Vertex2 ������� ����� }
    function IncidentToVertex(Vertex: TVertex): Bool;
    { ���������, ���������� �� ������� Vertex ����� (�.�. �������� �� ���
      ����� �� ������ �����) }
    function IncidentToEdgeUndirected(Edge: TEdge): Bool;
    { ���������, ���������� �� ����� Self � Edge; ���� ������, ���������� ��
      Features, ���������������� ��� �����������������, �.�. True ������������,
      ���� ���� �� ������ ����� Self ��������� � ����� �� ������ ����� Edge }
    function IncidentToEdgeDirected(Edge: TEdge): Bool;
    { ���������, ���������� �� ����� Self � Edge; ���� ������, ���������� ��
      Features, ���������������� ��� ���������������, �.�. True ������������,
      ���� ����� ������ �� ����� ��������� � ������� ������� }
    function IncidentToEdge(Edge: TEdge): Bool;
    { ���������, ���������� �� ����� Self � Edge; ���� ����������������
      ��� ����������������� ��� ��������������� � ����������� �� Features }
    function ParallelToEdgeUndirected(Edge: TEdge): Bool;
    { ���������, �������� �� ����� Self � Edge �������������; ���� ������,
      ���������� �� Features, ���������������� ��� �����������������, �.�.
      ����� ��������� �������������, ���� ��� ���������� ����� � ��� ��
      ��������������� ���� ������ }
    function ParallelToEdgeDirected(Edge: TEdge): Bool;
    { ���������, �������� �� ����� Self � Edge �������������; ���� ������,
      ���������� �� Features, ���������������� ��� ���������������, �.�.
      ����� ��������� �������������, ���� ��� ���������� ����� � ��� ��
      ������������� ���� ������ }
    function ParallelToEdge(Edge: TEdge): Bool;
    { ���������, �������� �� ����� Self � Edge �������������; ���� ����������������
      ��� ����������������� ��� ��������������� � ����������� �� Features }
    function OtherVertex(Vertex: TVertex): TVertex;
    { ���� Vertex �������� ����� �� ������ �����, �� ���������� ������ ��� �����,
      ����� - nil }
    function IsLoop: Bool;
    { �������� �� ����� ������ }
    function RingEdge: Bool;
    { �������� �� ����� ���������, �.�. ���������� �� ������� (���� � ������
      �������) �� V1 � V2, �� ���������� ����� ��� ����� (����); ���������
      ����� �� ���������; ����� ��������� ���������� ������� }
    procedure Hide;
    { "������" (�������� �������) �����; �������� ���� Temp; "�������" �����
      �� ������������ ��� ����������� �����, ������� �� ����������
      ��������������� ���� ���������� ������� ����� ������������ �����; ������
      � ��������� "�������" ����� ���������� }
    procedure Restore;
    { ������������ �����, "�������" ����� ������� Hide; ���� �� ������
      ������������ ������������ ����� Hide (�.�. � ���� �� ������ �����������
      � �� ���� �� ������ ��������� ������� ��� �����); ����� ����������
      ��������������� � �������, �������� "��������" }

    { *** ������� }

    procedure ChangeDirection;
    { �������� ����������� ����� �� ��������������� }

    { *** ������������ ���� }

    property MaxFlow: Float read GetMaxFlow write SetMaxFlow;
    { ������������ ����� ����� ���� }
    property Flow: Float read GetFlow write SetFlow;
    { ����� ����� ���� }

    { *** ���������� ����� }

    property Weight: Float read GetWeight write SetWeight;
    { ��� ����� (����) }
  end;

  TGraphFeature = (Directed, Tree, Network, Weighted, Geom2D, Geom3D);
  { �������� �����: ������������ ����, ������, ������������ ����, ����������
    ����, �������������� ���� �� ��������� � � ���������� ������������;
    �������� ������� ��������� ����������� � Run-Time ������ �������,
    �� ��������������� ��� ������ ������� ���� � ���������� ��� ���� ����������
    (�������� ������� ����������� ������ ��� ���������� ������� ����������
    CHECK_GRAPHS); ����� ����, ������������� ������� �������� ������������� -
    ��������, ����������� ��� ������ ������� ����, ����������� ������ �����,
    ����� ���� �������, ��� ���� ��������� � ����� ���� }

  TGraphFeatures = set of TGraphFeature;

  TVisitProc = procedure (V: TVertex) of object;
  TAcceptVertex = function (V: TVertex): Bool of object;
  TAcceptEdge = function (Edge: TEdge; FromVertex: TVertex): Bool of object;

  TEdgeFilter = class
    AllowedEdges: TBoolVector;
    function AcceptEdge(Edge: TEdge; FromVertex: TVertex): Bool;
  end;

  TAutoEdgeFilter = class(TEdgeFilter)
    constructor Create(EdgeCount: Integer);
    destructor Destroy; override;
  end;

  TSelectCode = (SelectAll, SelectAny, SelectSpecified, SelectAnyMin, SelectAnyMax,
    SelectAllMin, SelectAllMax, SelectAllGE, SelectAllLE);
  { ������������ � FindMaxIndependentVertexSets ��� ��������, ����� ������������
    ����������� ��������� ������ �/��� ������� �������� ������� ��������:
    SelectAll: ��� ���������;
    SelectAny: ����� �� ��������;
    SelectSpecified: �������� ���������� ����������;
    SelectAnyMin: ����� ��������� ����������� ��������;
    SelectAnyMax: ����� ��������� ������������ ��������;
    SelectAllMin: ��� ��������� ����������� ��������;
    SelectAllMax: ��� ��������� ������������ ��������;
    SelectAllGE: ��������, ������� ���� ������ �������� ���������;
    SelectAllLE: ��������, ������� ���� ������ �������� ���������;
  }

  TGraph = class(TGraphObject)
  protected
    FFeatures: TGraphFeatures;
    FConnected: Bool;
    FSeparateCount, FRingEdgeCount: Integer;
    FVertexAttrMap, FEdgeAttrMap: TAttrMap; { ����� ���������� ��������� ������ � ����� }
    FVertices, FEdges: TClassList;
    procedure SetStates(NewStates: TGraphObjectStates);
    property States: TGraphObjectStates read FStates write SetStates;
    procedure FreeElements;
    function GetVertex(I: Integer): TVertex; {$IFDEF V_INLINE}inline;{$ENDIF}
    function GetEdgeByIndex(I: Integer): TEdge; {$IFDEF V_INLINE}inline;{$ENDIF}
    procedure InsertVertex(Vertex: TVertex);
    { ���������� ����������� ��������� � ����� ��� ���������� �������; ����������
      �� TVertex.Create; ��� � ����������� ��������� ������� ��� ����, �����
      ������� ���� � �������� ����� ����� "������������" (������ ��������� �����
      �� ����������� �� ������ ������ protected-���� �����) }
    procedure RemoveVertex(Vertex: TVertex);
    { ���������� ����������� ��������� � ����� ��� �������� �������; ����������
      �� TVertex.Destroy }
    procedure InsertEdge(Index: Integer; Edge: TEdge);
    { ���������� ����������� ��������� � ����� ��� ���������� �����; ����������
      �� TEdge.Create }
    procedure RemoveEdge(Edge: TEdge);
    { ���������� ����������� ��������� � ����� ��� �������� �����; ����������
      �� TEdge.Destroy � TEdge.Hide }
    procedure DetectConnected;
    { ����������, ������ �� ���� }
    procedure DetectSeparates;
    { ������� ���������� ��������� }
    function DetectRingsAcceptEdge(Edge: TEdge; FromVertex: TVertex): Bool;
    { ��������������� ������� ��� ������ ��������� ����� � ����� }
    function DetectRingsAcceptArc(Edge: TEdge; FromVertex: TVertex): Bool;
    { ��������������� ������� ��� ������ ��������� ����� � ������� }
    function FindMinRingAcceptEdge(Edge: TEdge; FromVertex: TVertex): Bool;
    { ��������������� ������� ��� ������ ������ � ����� }
    procedure DetectRingEdges;
    { ������� ��������� ����� }
    procedure CheckValidConnected;
    { ��� ������������� ����������, ������ �� ���� }
    procedure CheckValidSeparates;
    { ��� ������������� ������� ���������� ��������� }
    procedure CheckValidRingEdges;
    { ��� ������������� ������� ��������� ����� � ���������� ��������� }
    procedure SetFeatures(Value: TGraphFeatures);
    { ������������� �������� ����� }
    function FFindMinPathCond(Vertex1, Vertex2: TVertex;
      AcceptVertex: TAcceptVertex; AcceptEdge: TAcceptEdge;
      EdgePath: TClassList): Integer;
    { ������������ ��� ���������� ����������� ����� (��. FindMinPathCond);
      ��������! EdgePath ������ ���� ���� ����� ������� }
    function FFindMinPaths(Vertex1, Vertex2: TVertex; SolutionCount: Integer;
      EdgePaths: TMultiList; DirectedGraph: Bool): Integer;
    { ������������ ��� ���������� ��������� ���������� / ���� ����������� �����
      (��. FindMinPaths) }
    function FFindMinRingCond(Vertex: TVertex; AcceptVertex: TAcceptVertex;
      AcceptEdge: TAcceptEdge; EdgePath: TClassList): Integer;
    { ������������ ��� ���������� ����������� ����� (��. FindMinRingCond) }
    procedure SetToZero(List: TClassList; Offset: Integer; AType: TAttrType);
    { ������������ ��� ��������� �������� ����� ��������� ���������, ����� ���
      ��������� �� ����� "���", ������������ ����� DropAttr }
    procedure FFindRingsFromEdge(FromEdge: TEdge; Rings: TMultiList;
      MaxRings: Integer; FindRingFromEdgeHelper: Pointer);
    { ������������ ��� ���������� ����������� ����� }

    { *** ������� }

    function AcceptArc(Edge: TEdge; FromVertex: TVertex): Bool;
    { ������������ ��� ���������� ������������ ���� }

    { *** ������� }

    function GetRoot: TVertex; {$IFDEF V_INLINE}inline;{$ENDIF}
    procedure SetRoot(Vertex: TVertex);

    { *** ������������ ���� }

    function GetNetworkSource: TVertex; {$IFDEF V_INLINE}inline;{$ENDIF}
    procedure SetNetworkSource(Vertex: TVertex); {$IFDEF V_INLINE}inline;{$ENDIF}
    function GetNetworkSink: TVertex; {$IFDEF V_INLINE}inline;{$ENDIF}
    procedure SetNetworkSink(Vertex: TVertex); {$IFDEF V_INLINE}inline;{$ENDIF}
    function FindMaxFlowAcceptEdge(Edge: TEdge; FromVertex: TVertex): Bool;

    { *** ���������� ����� }
    procedure Dijkstra(Vertex1, Vertex2: TVertex; AcceptVertex: TAcceptVertex;
      AcceptEdge: TAcceptEdge; Distances: TFloatVector);
  public
    constructor Create;
    destructor Destroy; override;
    procedure WriteToStream(VStream: TVStream); override;
    procedure ReadFromStream(VStream: TVStream); override;
    procedure Assign(Source: TVector); override;
    procedure AssignSceleton(Source: TGraph);
    { �������� � Self "������" ����� Source (�.�. ����, ������������� Source,
      �� ��� ���������) }
    procedure AssignSimpleSceleton(Source: TGraph);
    { �������� � Self ������� "������" ����� Source (�.�. ����, �������������
      Source, �� ��� ������, ������� ����� � ���������) }
    procedure Pack; override;
    procedure Clear; override;
    { ���������� ��� ������� � ����� ����� }
    procedure ClearEdges;
    { ���������� ��� ����� ����� }
    property Features: TGraphFeatures read FFeatures write SetFeatures;
    { �������� ����� }
    function VertexCount: Integer; {$IFDEF V_INLINE}inline;{$ENDIF}
    { ���������� ������ ����� }
    function EdgeCount: Integer; {$IFDEF V_INLINE}inline;{$ENDIF}
    { ���������� ����� ����� }
    property Vertices[I: Integer]: TVertex read GetVertex; default;
    { ������� ����� 0..VertexCount-1 }
    property Edges[I: Integer]: TEdge read GetEdgeByIndex;
    { ����� ����� 0..EdgeCount-1 }
    function Connected: Bool;
    { ���������, �������� �� ���� �������; ���� ��� ������ ��������� ���������;
      ���� ������ ���������������� ��� ����������������� }
    function MakeConnected(NewEdges: TClassList): Integer;
    { ���� ���������� ������ � ����� ������ 0, �� ������ ���� �������, ��������
      ��� ������������� ����� ����� (����� �� ������ ������� ������ ��������
      ������� ��� ������� 0); ���������� ���������� ����������� �����; ����
      NewEdges <> nil, �� � NewEdges ������������ ������ ����� ����� }
    function FindArticulationPoints(FromVertex: TVertex; Points: TClassList): Bool;
    { ������� ����� (����) ����������, ������������� ��� �� ���������� ���������
      �����, ��� � FromVertex (������ ���������� ���������� �������, ��������
      ������� �������� � ���������� ����� ��������� ���������); ���������� True,
      ���� ����� ���������� ����������, ����� - False; ���� Points <> nil, �� �
      Points ������������ ������ ����� ���������� }
    function Biconnected(ArticulationPoints: TClassList): Bool;
    { ���������, �������� �� ���� ���������� (���� ���������� ����������, ����
      �� ������ � � ��� �� ���������� ����� ����������; ����, ��������� �� �����
      �������, �������� ���������� �� �����������); ���������� True, ���� ����
      �������� ����������, ����� - False; ���� ���� �������� �������, ��
      �� ����������, � ArticulationPoints <> nil, �� � ArticulationPoints
      ������������ ������ ����� ���������� ����� }
    function MakeBiconnected(NewEdges: TClassList): Integer;
    { ������ ���� ���������� � ���������� ���������� ����������� �����; ����
      NewEdges <> nil, �� � NewEdges ������������ ������ ����������� ����� }
    function Bipartite(A: TBoolVector): Bool;
    { ���������, �������� �� ���� ���������� (�.�. ��� ������� ����� ������� ��
      ��� ����� ��������� A � B, ��� ��� ������� ����� ����� ���� �� ������
      ����� � A, � ������ - � B); ���� ����� ���� ��������� (� ����� ������ ��
      ������� �� ���������� ���������� ������� ���������� ��������� �/���
      ���������� ������������� ������; ���� A <> nil, �� ��� �������������
      ���������� (���� ����������) � A ������������ ���������� � ��������������
      ������ � �����: A[I] = True <=> I-�� ������� ����� � A }
    function IsTree: Bool;
    { ���������, �������� �� ���� ������� (������� ������ ��� ������ � �������
      �����); �� ������� ������ ��� ������� � �������� ����� Tree - ��� �����
      �� ������� }
    function IsRegular: Bool;
    { ���������, �������� �� ���� ���������� ������ (�.�. ������� ���� ���
      ������ ���������); ���� ������ ���������������� ��� �����������������;
      ���� ��� ������ ��������� ���������� }
    function HasParallelEdges: Bool;
    { ���������, ������� �� � ����� ������� �����; ���� ���������������� ���
      ����������������� ��� ��������������� � ����������� �� Features }
    {$IFDEF V_ALLOW_DEPRECATE}
    function HasDuplicateEdges: Bool; { ��������! }
    {$ENDIF}
    function HasLoops: Bool;
    { ���������, ������� �� � ����� ����� }
    function RemoveParallelEdges: Bool;
    { ������� ��� ������� ����� (���� � �������) � ���������� True, ���� � �����
      ������������ ������� ����� (����) }
    {$IFDEF V_ALLOW_DEPRECATE}
    function RemoveDuplicateEdges: Bool; { ��������! }
    {$ENDIF}
    function RemoveLoops: Bool;
    { ������� ��� ����� � ���������� True, ���� � ����� ������������ ����� }
    function HideLoops(Loops: TClassList): Integer;
    { "��������" (�������� ������� ������� Hide) ��� ����� � �������� �� �
      ������ Loops; "�������" ����� �� ������������ ��� ����������� �����,
      ������� �� ���������� ��������������� ���� ���������� ������� �����
      ������������ �����; ���������� ���������� ������ � �����; ����� �����
      ������������ ������� RestoreLoops }
    procedure RestoreLoops(Loops: TClassList);
    { ��������������� �����, ��������� ������� HideLoops; ���� ���� ��� �������
      (�.�. ����������� ���������� ��� ����������� ������ ��� �����), ��
      �������������� ���������� }
    function ParallelEdgeCount: Integer;
    { ���������� ������� ����� � ����� }
    {$IFDEF V_ALLOW_DEPRECATE}
    function DuplicateEdgeCount: Integer; { ��������! }
    {$ENDIF}
    function LoopCount: Integer;
    { ���������� ������ � ����� }
    function SeparateCount: Integer;
    { ���������� ��������� ��������� � ����� }
    function RingEdgeCount: Integer;
    { ���������� ��������� �����, ������� �����, � ����� }
    function CyclomaticNumber: Integer;
    { ��������������� ����� ����� (EdgeCount - VertexCount + SeparateCount) }
    function CreateVertexAttr(const Name: String; AType: TAttrType): Integer;
    { ���������� ���������� (����� ��� ���� ������) ������� ������ ����� �
      ������ Name � ����� AType; ��������� �������� ��� �������� ��������� - 0,
      ��� ���������� - nil, ��� ����� - ''; ���������� �������� ��������;
      ���� ������� � ����� ������ ��� ��� ���������, �� ������������
      �������������� �������� }
    procedure DropVertexAttr(const Name: String);
    { ������� ���������� ������� ������ ����� � ������ Name; ���� ����� �������
      �� ��� ���������, �� ������������ �������������� �������� }
    function CreateEdgeAttr(const Name: String; AType: TAttrType): Integer;
    { ���������� ���������� (����� ��� ���� �����) ������� ����� ����� �
      ������ Name � ����� AType; ��������� �������� ��� �������� ��������� - 0,
      ��� ���������� - nil, ��� ����� - ''; ���������� �������� ��������;
      ���� ������� � ����� ������ ��� ��� ���������, �� ������������
      �������������� �������� }
    procedure DropEdgeAttr(const Name: String);
    { ������� ���������� ������� ����� ����� � ������ Name; ���� ����� �������
      �� ��� ���������, �� ������������ �������������� �������� }
    function VertexAttrType(const Name: String): TExtAttrType;
    { ���������, ��������� �� ���������� ������� ������ ����� � ������ Name
      � ���������� ��� ���, ���� AttrNone, ���� �� ��������� }
    function SafeCreateVertexAttr(const Name: String; AType: TAttrType): Integer;
    { ������ CreateVertexAttr, �� ��� ������� �������� � ������ Name � �����
      AType ������������ -1, �������������� �������� �� ������������ }
    procedure SafeDropVertexAttr(const Name: String);
    { ������ DropVertexAttr, �� ��� ���������� �������� � ������ Name
      �������������� �������� �� ������������ }
    function SafeCreateEdgeAttr(const Name: String; AType: TAttrType): Integer;
    { ������ CreateEdgeAttr, �� ��� ������� �������� � ������ Name � �����
      AType ������������ -1, �������������� �������� �� ������������ }
    procedure SafeDropEdgeAttr(const Name: String);
    { ������ DropEdgeAttr, �� ��� ���������� �������� � ������ Name
      �������������� �������� �� ������������ }
    function EdgeAttrType(const Name: String): TExtAttrType;
    { ���������, ��������� �� ���������� ������� ����� ����� � ������ Name
      � ���������� ��� ���, ���� AttrNone, ���� �� ��������� }
    function VertexAttrOffset(const Name: String): Integer;
    { ���������� �������� ����������� �������� ������ ����� � �������� ������
      (������� ������ ���� ���������) }
    function EdgeAttrOffset(const Name: String): Integer;
    { ���������� �������� ����������� �������� ����� ����� � �������� ������
      (������� ������ ���� ���������) }
    property VertexAttrMap: TAttrMap read FVertexAttrMap;
    { ����� ���������� ��������� ������ ����� }
    property EdgeAttrMap: TAttrMap read FEdgeAttrMap;
    { ����� ���������� ��������� ����� ����� }
    function AddVertex: TVertex;
    { ������� � ��������� � ���� �������; ������� ����������� � �����
      ������ ������ }
    procedure AddVertices(ACount: Integer);
    { ������� � ��������� ACount ������ � ����; ������� ����������� � �����
      ������ ������ }
    function GetEdge(Vertex1, Vertex2: TVertex): TEdge;
    { ���������� �����, ����������� �������� Vertex1 � Vertex2, ���� ��� �������
      ������, ����� - nil; ��� ������� ������� ����� ����� ��������� �����
      ������������ ����� �� ���; ������� ���������� �� �����; ����� �� ����������
      ����� ���� ����� nil, ��� ���� ��������� ����� ����� ����� nil }
    function GetEdgeI(I1, I2: Integer): TEdge;
    { ���������� �����, ����������� �������� � ��������� I1 � I2, ���� ���
      ������� ���������� � ������, ����� - nil; ��� ������� ������� ����� �����
      ��������� ����� ������������ ����� �� ���; ������� ���������� �� ����� }
    procedure GetEdges(EdgeList: TClassList; Vertex1, Vertex2: TVertex);
    { ���������� � EdgeList ������ �����, ����������� �������� ��������, ����
      ��� ������� ������, ����� - ������ ������; ������� ���������� �� �����;
      � Vertex1, � Vertex2 ����� ���� ����� nil, ��� ���� ������������ ������
      ������ }
    procedure GetEdgesI(EdgeList: TClassList; I1, I2: Integer);
    { ���������� � EdgesList ������ �����, ����������� �������� � ��������� I1 �
      I2, ���� ��� ������� ���������� � ������, ����� - ������ ������; �������
      ���������� �� ����� }
    function AddEdge(Vertex1, Vertex2: TVertex): TEdge;
    { ������� � ��������� � ���� ����� ����� ��������� Vertex1 � Vertex2; �����
      ����������� � ����� ������ ����� }
    function AddEdgeI(I1, I2: Integer): TEdge;
    { ������� � ��������� � ���� ����� ����� ��������� � ��������� I1 � I2;
      ����� ����������� � ����� ������ ����� }
    procedure AddEdges(const VertexIndexes: array of Integer);
    { ������� � ��������� � ���� ����� ����� ��������� � ��������� VertexIndexes
      (���������� ��������� � VertexIndexes ������ ���� ������):
      VertexIndexes[0]..VertexIndexes[1],
      VertexIndexes[2]..VertexIndexes[3]... � �.�. }
    procedure GetSeparateOf(Source: TGraph; V: TVertex);
    { ������ ���� Self ������ ���� ���������� ��������� ����� Source, ��������
      ����������� ������� V; ������������ ����� ��������� ����� Self � �����
      Source ��������������� � ������� ���� Temp: ����� ���������� ������
      ��������� Vertices[I].Temp.AsInt32 = <������ ������� � ����� Source,
      ������� ������������� ������� Vertices[I]>;
      ����������: �������� ������ � ����� �� ����������; Source �� �����
      ��������� � Self }
    procedure SetTempForVertices(Value: Int32);
    { ����������� ����� Temp ���� ������ ����� �������� Value }
    procedure SetTempForEdges(Value: Int32);
    { ����������� ����� Temp ���� ����� ����� �������� Value }
    procedure SetTempFromVertex(V: TVertex; Value: Int32);
    { ����������� ����� Temp ���� ������ �����, ����������� � ����� ����������
      ��������� � V, �������� Value }
    function DFSFromVertex(V: TVertex): Integer;
    { ��������� �������� ������ ����� � ������� ������ � ������� (Depth First
      Search), ������ �� ������� V; ���� Temp ������ ����������� �������
      ������������� �����, ������ "�������" ���������� ������ ������� (0 ���
      ������� V); ������������ ���������� ����������� ������, ������ ����������
      ������, ������������� ��� �� ���������� ��������� �����, ��� � V; �����
      Temp ������, ������������� ������ ����������� ���������, �������������
      �������� -1; ���� ������, ���������� �� Features, ���������������� ���
      ����������������� }
    function BFSFromVertex(V: TVertex): Integer;
    { ��������� �������� ������ ����� � ������� ������ � ������ (Breadth First
      Search; ������ �������� - �������� ��������, ��� �������� �������� ������),
      ������ �� ������� V � ��������� � �������� "��������� �����" ���� Temp
      (������� V �������� ����� 0); ������������ ���������� ����������� ������,
      ������ ���������� ������, ������������� ��� �� ���������� ��������� �����,
      ��� � V; �������, ������������� ������ ����������� ���������, ��������
      ����� -1; ���� ������, ���������� �� Features, ���������������� ���
      ����������������� }
    function BFSTraversal(V: TVertex; VisitProc: TVisitProc): Integer;
    { ������ BFSFromVertex; ���� VisitProc <> nil, �� ��� ���������� ���������
      ������� ��� ������� ���������� � call-back ��������� VisitProc (������� V
      �� ���������� � VisitProc) }
    function BFSFromVertexFindMeetings(V: TVertex; VertexMeetings,
      EdgeMeetings: TClassList): Integer;
    { ������ BFSFromVertex, �� ������� "�����" �� �������� � ������ �����
      ������������ � VertexMeetings / EdgeMeetings; �� ����� ������� ��� �����
      ����� ����� ��������� ����� ��� ���� �������, ������� � ������� ��������
      �������;
      ����������:
      1) ���� ���� �������, �� ����������� �����������:
         CyclomaticNumber = VertexMeetings.Count +  EdgeMeetings.Count + LoopCount;
      2) ����������� VertexMeetings = nil, �� ����� � EdgeMeetings ���������
         ������ nil }
    procedure BFSFromVertexDirected(V: TVertex);
    { ������ BFSFromVertex, �� ���� ������, ���������� �� Features,
      ���������������� ��� ��������������� }
    function FindMinPathCond(Vertex1, Vertex2: TVertex; AcceptVertex: TAcceptVertex;
      AcceptEdge: TAcceptEdge; EdgePath: TClassList): Integer;
    { ������� ����� �� ����� ����������� ����� ����� ��������� ���������,
      ���������� ����� �������, ��������������� ������� AcceptVertex � �����
      �����, ��������������� ������� AcceptEdge, � ���������� ��� �����
      (-1, ���� ���� �� ����������, � 0, ���� Vertex1 = Vertex2); ����
      AcceptVertex = nil, �� ����������� ��� �������; ���� AcceptEdge = nil,
      �� ����������� ��� �����; ���� EdgePath <> nil, �� � EdgePath ����������
      ��������� �� �����, �� ������� �������� ����; ���� ������, ���������� ��
      Features, ���������������� ��� ����������������� }
    function FindMinPathUndirected(Vertex1, Vertex2: TVertex;
      EdgePath: TClassList): Integer;
    { ������� ����� �� ����� ����������� ����� ����� ��������� Vertex1 � Vertex2;
      ���� ������, ���������� �� Features, ���������������� ��� ����������������� }
    function FindMinPathDirected(Vertex1, Vertex2: TVertex;
      EdgePath: TClassList): Integer;
    { ������� ����� �� ����� ����������� ����� ����� ��������� Vertex1 � Vertex2;
      ���� ������, ���������� �� Features, ���������������� ��� ��������������� }
    function FindMinPath(Vertex1, Vertex2: TVertex; EdgePath: TClassList): Integer;
    { ������� ����� �� ����� ����������� ����� ����� ��������� Vertex1 � Vertex2;
      ���� ���������������� ��� ����������������� ��� ��������������� �
      ����������� �� ��������� ����� Directed �� ��������� Features }
    function FindMinPathsUndirected(Vertex1, Vertex2: TVertex;
      SolutionCount: Integer; EdgePaths: TMultiList): Integer;
    { ���� ���� ����� ��������� Vertex1 � Vertex2, ����� ������� ����� �����
      ������������ ���� ����� ����� ���������; ���� SolutionCount <= 0, ��
      ������������ ��� ����� ����; ���� SolutionCount > 0, �� ������������
      min(SolutionCount, <���������� �����>) �����; ������� ����������
      ���������� ��������� �����; ���� ������������ � ������������ EdgePaths
      (������ ������� EdgePaths �������� ������� ����� �����, ����������
      ��������� ����); ���� ������, ���������� �� Features, ����������������
      ��� ����������������� }
    function FindMinPathsDirected(Vertex1, Vertex2: TVertex;
      SolutionCount: Integer; EdgePaths: TMultiList): Integer;
    { ������ FindMinPathsUndirected, �� ���� ������ ���������������� ���
      ��������������� }
    function FindMinPaths(Vertex1, Vertex2: TVertex; SolutionCount: Integer;
      EdgePaths: TMultiList): Integer;
    { ������ FindMinPathsUndirected, �� ���� ���������������� ���
      ��������������� ��� ����������������� � ����������� �� ��������� �����
      Directed �� ��������� Features }
    function FindMinRingCond(Vertex: TVertex;
      AcceptVertex: TAcceptVertex; AcceptEdge: TAcceptEdge;
      EdgePath: TClassList): Integer;
    { ������� ����� �� ������ ����������� �����, ���������� ����� ������� Vertex
      � ������ �������, ��������������� ������� AcceptVertex, � �� ������,
      ��������������� ������� AcceptEdge; ������������ ����� ����� (-1, ����
      ���� �� ����������); ���� AcceptVertex = nil, �� ����������� ��� �������;
      ���� AcceptEdge = nil, �� ����������� ��� �����; ���� EdgePath <> nil,
      �� � EdgePath ���������� ��������� �� �����, �� ������� �������� ����;
      ���� ������, ���������� �� Features, ���������������� ��� ����������������� }
    function FindMinRing(Vertex: TVertex; EdgePath: TClassList): Integer;
    { ������� ����� �� ������ ����������� �����, ���������� ����� �������
      Vertex; ���� ���������������� ��� ����������������� ��� ���������������
      � ����������� �� Features }
    function CreateRingDegreesVector: TIntegerVector;
    { ������� ������ ��������� �������� (��� ����� ������) ������ �����;
      Result[I] = <���������� ��������� �����, ����������� I-� ������� �����> -
      <���������� ������, ����������� I-� ������� �����>; ���� ������,
      ���������� �� Features, ���������������� ��� ����������������� }
    function FindRingsFromEdge(FromEdge: TEdge; Rings: TMultiList;
      MaxRings: Integer): Integer;
    { ������� �� �����, ��� MaxRings ����������� ����������� �����, ����������
      ����� ����� FromEdge; ���������� ���������� ��������� �����, � ����� ����
      ������ � ������������ Rings (Rings[I] �������� ������ ���������� �� �����,
      �������� � I-� ����������� ������) }
    function FindMinRingCovering(Rings: TMultiList): Integer;
    { ������� ������� ����������� ����������� ����� �����, ����������� ���
      ��������� ����� ����� (�������� �����) � ���������� ���������� �����,
      � ����� ���� ������ � ������������ Rings; ���� ������, ���������� ��
      Features, ���������������� ��� �����������������;
      ����������:
      1) ��� ��������� ������ ������� ����������� ����������� ����������� �����
         �������� ����� �������� ����������� ����������� �����, ��� ������ -
         �������� ������������� ���������, �.�. ���������� ����� � �������
         ����������� ����� ����� ���� ������ ���������������� �����
         ����� ����� ���������� ������;
      2) ������� ����������� ����������� ����������� ����� ����� � ����� ������
         �� ����������� }
    function CompleteRingSystem(Rings: TMultiList): Bool;
    { ���������, ��� ��� ��������� ����� ����� (����� ������) "�����������"
      �������� ����� Rings, �.�. ����������� ���� �� ������ ������ }
    function FindSpanningTree(EdgeInST: TBoolVector; STEdges: TClassList): Integer;
    { ������� ���� �� �������� �������� �����; ���������� ���������� ����� �
      �������� ������; ���� EdgeInST <> nil, �� EdgeInST[I] = True <=> I-�
      ����� ������ � �������; ���� STEdges <> nil, �� � STEdges ������������
      ������ �����, �������� � ������ (�������� ������� �����, ��� �������,
      ���������� ����� ��� �������, ���������� ������� �� ������ � ���������
      ���������, ��� � ���� ����, � �� ���������� ������; ������ ������, �����
      �� ������ �������� ������� - ��� ���������� ����� ��� ��� ��������) }
    function FindFundamentalRings(Rings: TMultiList): Integer;
    { ������� ��������� ������� ��������������� ������ ����� (�������� �����);
      ���������� ���������� ������; ����� ������������ � ������������ Rings
      (Rings[I] �������� ������ ���������� �� �����, �������� � I-� ����);
      ��������������� �������� ������ ���������� ����� ������� ������, �������
      ����� ���� ��������� ����� ���������� � ���������� ������ ����� ��� ����
      (�����, �� ������������� ������); ���������� ������ � ���������������
      ������� ����� ���������������� ����� ����� ����� ���������� ������ }
    function EdgePathToVertexPath(FromVertex: TVertex;
      EdgePath, VertexPath: TClassList): Bool;
    { ����������� ����, �������� ������� ����� � ������������ � �������
      FromVertex, � ������ ������; ���������� True ��� ������ � False ���
      ������ � EdgePath }
    function CreateConnectionMatrix: TBoolMatrix;
    { ������� ������� ��������� (aij = True <=> ������� vi � vj ��������� ������
      ���� �����; aii = True); ���� ���� �����������������, �� ���������
      ������������ ������� }
    function CreateExtendedConnectionMatrix: TIntegerMatrix;
    { ������� ���������� ������� ��������� (aij = <���������� ����� (���) �����
      ��������� vi � vj>; aii = <���������� ������, ����������� vi>; ���� ����
      �����������������, �� ��������� ������������ ������� }
    function CreateReachabilityMatrix: TBoolMatrix;
    { ������� ������� ������������ (aij = True <=> ������� vj ��������� �� vi;
      aii = True); ���� ���� �����������������, �� ��������� ������������ ������� }
    function CreateIncidenceMatrix: TBoolMatrix;
    { ������� ������� ���������� ����� (������� ����������� VertexCount*EdgeCount,
      ��� bij = True <=> ������� vi ���������� ����� ej) }
    function CreateDistanceMatrix: TIntegerMatrix;
    { ������� ������� ���������� (dij = <����� ������������ ���� �� i-� �������
      � j-�>, ���� ���� ����������, � -1, ���� ���� �� ����������; dii = 0);
      ���� ���� �����������������, �� ��������� ������������ �������;
      ��� ����� � ������ ���������� ������ �� ����������� (�.�. ��� ������
      ����� ��������� ������ �������) }
    function CreateDegreesVector: TIntegerVector;
    { ������� ������ �������� ������ ����� }
    function CreateInt64DegreesVector: TInt64Vector;
    { ����������, �� ������� ������ ������ TInt64Vector }
    function UpdateSpectrum(Spectrum, SortedSpectrum, TempVector: TInt64Vector): Integer;
    { ��������� ��� ���������� ������� �� ������� ��� ������ �����; � �������
      Spectrum ������ ������������ ���������� ������, ��������� �������� ��������
      ����������� � ������� CreateInt64DegreesVector; �� ������ ������ Spectrum
      �������� ����������� �������� �������; ���� SortedSpectrum <> nil, �� �
      ��� ������������ ������������� �� ����������� �������� Spectrum; TempVector
      ������������ ������ ������� � �� ����� ���� ����� nil; ������� ����������
      ���������� ��������� �������� � ������� }
    function EqualToGraph(G: TGraph; IsomorphousMap: TGenericIntegerVector;
      CompareVertices, CompareEdges: TCompareFunc): Bool;
    { ����������, ��������� �� ����� Self � G ��� ����������� ������ Self ��
      ������� G, �������� IsomorphousMap (IsomorphousMap[I] = <����� ������� G,
      ��������������� I-� ������� Self>); ��� ��������� ��������� ������ � �����
      ������������ CompareVertices � CompareEdges; ����� Self � G ������ ����
      ���������� ����������� � �� ������ ��������� ������� �����; �������
      ��������������� ����� � ������� ����������� ����� (�������� IncidentEdge)
      ������ ��������� � ������ ��� ���� ������! }
    procedure FindMaxIndependentVertexSets(SelectCode: TSelectCode;
      SelectParam: Integer; VertexSets: TMultiList);
    { ������� ������������ ����������� ��������� ������ (����������� ���������
      ������, ��� - ��������� ������ �����, �����, ��� ������� ��� ������� �����
      ��������� �� ������� ������ / �����; ������������ ���, ���� - ����� ���,
      ��� ��� ���������� � ��� ��������� ����� ������ ������� ����� ���������
      ��������� ���� �����������) � ������� �� � ������������ VertexSets;
      ���������� ������������ �������� ������������ ��������� SelectCode;
      SelectParam: ������������ ��� SelectCode = SelectGE / SelectLE (��.
      ����������� � ���� TSelectCode), ��� ������ ��������� SelectCode ��������
      SelectParam ������������;
      ��������� ���������� �������-����������� ������������ ����� ���� �����
      � ������� (������������� ������� ����������) ��������������� � ���� �����,
      ����� FindMaxIndependentVertexSets ��������� ����� �������� ��� �����
      �����; ��� ����� ���� ��������� ���������� ����� � ������� ������
      GetComplementOf � ��������� � ���� ������ ����� }
    procedure GetComplementOf(Source: TGraph);
    { ������ ���� ����������� ����� Source (����������� ���������� �����
      ���������� ����, ������� �������� ��������� � ��������� ��������� �����,
      � ����� ��� ������� ��������� ������ ����� � ������ �����, ����� ��� ��
      ��������� ������ � �������� �����);
      ����������: � ���� �������������� ����� ������������; ��������� �����
      �� �����������; �������� ������ � ����� �� ����������; Source �����
      ��������� � Self }
    procedure GetLineGraphOf(Source: TGraph);
    { ������ ���� �������� ������ ����� Source (�������� ������ ����������
      ����� ���������� ����, ������� �������� ������������� ������ ���������
      �����, � ��� ������� ������� ����� � ������ �����, ����� ���������������
      �� ����� ������ � �������� �����, �.�. ����� ����� �����);
      ����������: �������� ������ � ����� �� ����������; Source �� �����
      ��������� � Self }
    function GetShortestSpanningTreeOf(Source: TGraph): Float;
    { ������ ���� ���������� �������� ������� (SST) ����������� ����� Source �
      ���������� ��������� ��� ��� ����� (���� Source ��������, �� ���������
      ��� ���������� �������� �������� ��� ������ ������� ���������� Source);
      ���� ���� �� ��� ����������, �� �� ���������� ���������� (Weighted in
      Features = True); ������������ ����� ��������� ����� Self � ����� Source
      ����������; ������������ ����� ������� ��������������� � ������� ����
      Temp: ����� ���������� ������ ������� Edges[I].Temp.AsInt32 = <������
      ����� � ����� Source, ������� ������������� ����� Edges[I]>; ���� ����
      Source �� �������� ����������, �� ������������ �������������� ��������;
      ����������: �������� ������ � ����� �� ����������; Source �� �����
      ��������� � Self }
    procedure SortVertices(CompareVertices: TCompareFunc);
    { ������������� ������� ����� �� ����������� �������� CompareVertices }
    procedure SortEdges(CompareEdges: TCompareFunc);
    { ������������� ����� ����� �� ����������� �������� CompareEdges }
    procedure SortVerticesByObject(CompareVertices: TCompareEvent);
    { ������������� ������� ����� �� ����������� �������� CompareVertices }
    procedure SortEdgesByObject(CompareEdges: TCompareEvent);
    { ������������� ����� ����� �� ����������� �������� CompareEdges }
    procedure GetVertices(VertexList: TClassList);
    { ���������� � VertexList ������ ������ ����� }

    { *** ������� }

    { ������ SetTempToSubtreeSize � TreeTraversal ����� ���� ��������� ��� �
      �������� (IsTree = True), ��� � � ������, ������� ����� ���� �������� ��
      �������� ����� ���������� ������� ������, ������������� ������ ������
      ������; ��� ������ ����� ������ ��������� �� ���������; ����� ArrangeTree
      ������ ����������� ������ � �������� }

    procedure SetTempToSubtreeSize(FromVertex: TVertex);
    { ������������� ���� Temp.AsInt32 ������ ����� ������� ���������� ������
      �� ���� ����������� ������� FromVertex; ��� ����� Temp.AsInt32 = 0, ����
      ����� "��������������" (�.�. ��������� �������, ������������� ������
      ������ ������), ����� Temp.AsInt32 = -1 }
    procedure TreeTraversal(FromVertex: TVertex; VertexPath: TClassList);
    { ��������� ����� ������ �����, ����������������� ��� ������ � ������
      FromVertex, ��������� ������� ������ ������ ���� / ����� �������;
      ��������� �� ���������� ������� ������������ � ������ VertexPath }
    procedure ArrangeTree(FromVertex: TVertex; CompareVertices,
      CompareEdges: TCompareEvent);
    { ������������� ������ � ������ FromVertex ���, ����� ���������� ������
      ������� ������������� ����� ������� �� ����������� ��������� ����������
      (� ������� ���������� ����������):
      1) ���������� ������ � �����������;
      2) ������� ������ �����������;
      3) �������� ������ �����������;
      4) �������� �����, ������� � �����������;
      5) �� ����������� ������������� ����������� (����������);
      ��� ��������� ��������� ������ � ����� ������������ �������
      CompareVertices � CompareEdges }
    procedure SortTree(FromVertex: TVertex; CompareVertices: TCompareEvent);
    { ���������� ��������� ������ � ������ FromVertex � ������������ �
      CompareVertices }

    { *** ������� }

    function GetArc(FromVertex, ToVertex: TVertex): TEdge;
    { ���������� ���� �� ������� FromVertex � ������� ToVertex, ���� ���
      ����������, ����� - nil; ��� ������� ������� ��� ����� ��������� �����
      ������������ ����� �� ���; ����� �� ���������� ����� ���� ����� nil,
      ��� ���� ��������� ����� ����� ����� nil }
    function GetArcI(FromIndex, ToIndex: Integer): TEdge;
    { ���������� ���� �� ������� � �������� FromIndex � ������� � ��������
      ToIndex, ���� ���� ����������, ����� - nil; ��� ������� ������� ��� �����
      ��������� ����� ������������ ����� �� ��� }
    procedure GetArcs(ArcsList: TClassList; FromVertex, ToVertex: TVertex);
    { ���������� � ArcsList ������ ��� �� ������� FromVertex � ������� ToVertex;
      � FromVertex, � ToVertex ����� ���� ����� nil, ��� ���� ������������ ������
      ������ }
    procedure GetArcsI(ArcsList: TClassList; FromIndex, ToIndex: Integer);
    { ���������� � ArcsList ������ ��� �� ������� � �������� FromIndex � �������
      � �������� ToIndex }
    procedure GetInArcsList(ArcsList: TMultiList);
    { ���������� � I-� ������� ������������ ArcsList ������ ���, ��������
      � I-�� ������� ����� }
    procedure GetOutArcsList(ArcsList: TMultiList);
    { ���������� � I-� ������� ������������ ArcsList ������ ���, ���������
      �� I-� ������� ����� }
    function FindStrongComponents(ComponentNumbers: TGenericIntegerVector): Integer;
    { ������� ������� ���������� ������� � ���������� �� ����������; ����
      ComponentNumbers <> nil, �� � ComponentNumbers ������������ ����������
      � �������������� ������ ����� � ������� �����������: ComponentNumbers[I] =
      <����� ������� ���������� ������� (������� � 0), ������� ����������� I-��
      ��� �������>; ������� ���������� ������� - ���� �� ������������ �������
      ��������� �������, �.�. ������� �������, ������� �� ���������� �� � �����
      ������ ������� ��������; ������� ������� - ����� ����������� �������
      �������, ��� ��� ����� ���� ������ ����� �������� ���������� �����������
      �� ���� }

    { *** ������� }

    procedure CorrectTree;
    { ������������� ���������� �������� Parent ��� ������ ������; ���� �����
      ��������� �����, ����� ������ ��������� �� ������ � ������� ������
      AddChild }
    property Root: TVertex read GetRoot write SetRoot;
    { ������ ������ }

    { *** ������������ ���� }

    function IsNetworkCorrect: Bool;
    { ��������� ������������ ������������ ����:
      1) ���� �� ��������� (�.�. � ��� ����� ����� �������);
      2) ���� ������;
      3) ���������� ������� ������ � �����;
      4) ��� ���, �������� � ����� ��� ��������� �� �����;
      5) ��� ������� ��� }
    function FindMaxFlowThroughNetwork: Float;
    { ������� ������������ ����� � ������������ ���� }
    property NetworkSource: TVertex read GetNetworkSource write SetNetworkSource;
    { ����� ������������ ���� }
    property NetworkSink: TVertex read GetNetworkSink write SetNetworkSink;
    { ���� ������������ ���� }

    { *** ���������� ����� }

    { 1. ����������� ������ ��������������� ���� ����� (���) }
    function FindMinWeightPathCond(Vertex1, Vertex2: TVertex;
      AcceptVertex: TAcceptVertex; AcceptEdge: TAcceptEdge;
      EdgePath: TClassList): Float;
    { ������� ����� �� ����� ������������ ���������� ���� ����� ���������
      ���������, ���������� ����� �������, ��������������� ������� AcceptVertex
      � ����� �����, ��������������� ������� AcceptEdge; ���������� ���������
      ��� ���������� ���� ���� ������������� �����, ���� ���� �� ����������;
      ���� AcceptVertex = nil, �� ����������� ��� �������; ����������, ����
      AcceptEdge = nil, �� ����������� ��� �����; ���� EdgePath <> nil, �� �
      EdgePath ���������� ��������� �� �����, �� ������� �������� ����; ����
      ������ ���������������� ��� ����������������� }
    function FindMinWeightPath(Vertex1, Vertex2: TVertex; EdgePath: TClassList): Float;
    { ������� ����� �� ����� ������������ ���������� ���� ����� ���������
      ��������� � ���������� ��� ��������� ���; ���� ���������������� ���
      ����������������� ��� ��������������� � ����������� �� Features }
    procedure FindDistancesCond(FromVertex: TVertex; AcceptVertex: TAcceptVertex;
      AcceptEdge: TAcceptEdge; Distances: TFloatVector);
    { ������� ����� ����� ������������ ���������� ���� ����� �������� FromVertex
      � ����� ������� ��������� �����; ���� �������� ����� �������,
      ��������������� ������� AcceptVertex � ����� �����, ���������������
      ������� AcceptEdge; ���� AcceptVertex = nil, �� ����������� ��� �������;
      ����������, ���� AcceptEdge = nil, �� ����������� ��� �����; ����� �����
      ������������ � Distances: Distances[I] = <���������� ����� ���������
      FromVertex � Vertices[I], ���� ����� ���� ���������� ����, ���������������
      �������� ��������, ���� MaxFloat, ���� ����� ���� �� ����������>; ����
      ������, ���������� �� Features, ���������������� ��� ����������������� }
    procedure FindDistances(FromVertex: TVertex; Distances: TFloatVector);
    { ������ FindDistancesCond, �� ���� ���������������� ��� �����������������
      ��� ��������������� � ����������� �� Features }

    { 2. ����������� ������������� ���� ����� (���) }
    function CreateWeightsMatrix: TFloatMatrix;
    { ������� � ���������� ������� ����� ����� (���); dij = <����� �����������
      ���� ����� ��������� � ��������� I � J>, ���� I <> J � ���� ����������,
      ����� dij = MaxFloat; ���� ���������������� ��� ����������������� ���
      ��������������� � ����������� �� ��������� ����� Directed �� ���������
      Features (��� ������������������ ����� ��������� ������������ �������) }
    function CreateMinWeightPathsMatrix(var DistancesMatrix: TFloatMatrix;
      PathsMatrix: TIntegerMatrix): Bool;
    { ������� ����������� ���������� ����� ����� ������ ������ ����������� �����
      � �������������� ��������� ������; ���� � ����� ��� ������ �������������
      �����, �� ������� ���������� True, � ������� DistancesMatrix[I, J], ���
      I <> J, �������� ����� ����������� ���� �� Vertices[I] � Vertices[J] (����
      ���� �� ����������, �� �� ����� MaxFloat); ���� DistancesMatrix[I, I] < 0,
      �� ������� I ������ � ���� ������������� �����; � ����� ������ �������
      ��������� ������ � ���������� False; ���� PathsMatrix <> nil, �� ���
      �������� ���������� ������ ��� �������� ����������, ����������� �����
      ���� ���� ����������� ����� (� ������� ������� DecodeMinWeightPath);
      ���� ���������������� ��� ����������������� ��� ��������������� �
      ����������� �� Features;
      ��������� ���������: O(VertexCount^3);
      ����������: ��� ��� True-, ��� � False-���������� ������� ����������
      ������� WeightMatrix, ������� ���������� ���������� ����� ������������� }
    function DecodeMinWeightPath(WeightMatrix: TFloatMatrix;
      PathsMatrix: TIntegerMatrix; I, J: Integer;
      VertexIndexes: TGenericIntegerVector): Bool;
    { ������� ���������� ���� ����� ��������� ����� � ��������� I � J �� ������
      ������ WeightMatrix � PathsMatrix, ��������� � ������� �������
      CreateMinWeightPathsMatrix, ���� ���� ����� ����� ��������� ����������;
      � ���� ������ ������� ���������� True, � ������� ������, �������� �
      ���������� ���� (������� I � J), ������������ � VertexIndexes; �����
      ������������ False }
    function FindShortestSpanningTree(SSTList: TClassList): Float;
    { ������� ���������� �������� ������ (SST) ����� (���� ���� ��������, ��
      ��������� ��� ���������� �������� ��������) � ���������� ��������� ���
      ��� �����; ���� SSTList <> nil, �� SSTList[I] = <��������� �� I-� �����,
      �������� � SST> }

    { *** �������������� ����� }

    procedure GetExtent2D(var MinX, MaxX, MinY, MaxY: Float);
    { ���������� ����������� � ������������ ���������� ������ ��������������
      2D-������ }
    procedure GetExtent3D(var MinX, MaxX, MinY, MaxY, MinZ, MaxZ: Float);
    { ���������� ����������� � ������������ ���������� ������ ��������������
      3D-������ }
    procedure AssignCoordinates(Source: TGraph);
    { ����������� ����������� ������ ����� Self ���������� ������ ����� Source;
      ����� ����� ����� ������ ���������� ������ (� ���� ������ ����������
      ���������� ������ min(Self.VertexCount, Source.VertexCount) ������);
      ���� Self �������� 2D-������, � Source - 3D, �� Z-���������� ������
      ����� Source ������������; ���� Self �������� 3D-������, � Source - 2D,
      �� Z-���������� ������ ����� Self �� �������� }
    procedure GetCoords2D(XCoords, YCoords: TFloatVector);
    { ��������� X � Y ���������� ������ ����� � �������� XCoords � YCoords }
    procedure GetCoords3D(XCoords, YCoords, ZCoords: TFloatVector);
    { ��������� X, Y � Z ���������� ������ ����� � �������� XCoords, YCoords �
      ZCoords }
    procedure SetCoords2D(XCoords, YCoords: TFloatVector);
    { ������������� X � Y ���������� ������ ����� �� �������� XCoords � YCoords }
    procedure SetCoords3D(XCoords, YCoords, ZCoords: TFloatVector);
    { ������������� X, Y � Z ���������� ������ ����� �� �������� XCoords,
      YCoords � ZCoords }
  end;

const
  { ���������� �������� (������ ���������� � '.') }
  { internal attributes (must begin with '.') }

  { ��� ����� } { All graphs }

  { �������� ������ } { vertex attributes }
  GAttrSeparateIndex = '.Separate';

  { �������� ����� } { edge attributes }
  GAttrRingEdge = '.Ring';

  { ������� } { Trees }

  { �������� ����� } { graph attributes }
  GAttrRoot = '.Root';

  { �������� ������ } { vertex attributes }
  GAttrHasParent = '.HasPrnt';
  GAttrX = '.X';
  GAttrY = '.Y';
  GAttrZ = '.Z';

  { ���� } { Networks }

  { �������� ����� } { graph attributes }
  GAttrNetworkSource = '.NwSrc';
  GAttrNetworkSink = '.NwSink';

  { �������� ����� } { edge attributes }
  GAttrMaxFlow = '.MaxFlow';
  GAttrFlow = '.Flow';

  GAttrWeight = '.Weight';

implementation

{ TGraphObject }

procedure TGraphObject.WriteToStream(VStream: TVStream);
begin
  inherited WriteToStream(VStream);
  VStream.WriteProc(FStates, SizeOf(FStates));
  VStream.WriteProc(FTemp, SizeOf(FTemp));
end;

procedure TGraphObject.ReadFromStream(VStream: TVStream);
begin
  inherited ReadFromStream(VStream);
  VStream.ReadProc(FStates, SizeOf(FStates));
  VStream.ReadProc(FTemp, SizeOf(FTemp));
end;

procedure TGraphObject.Assign(Source: TVector);
begin
  if Source is TGraphObject then begin
    inherited Assign(Source);
    FIndex:=TGraphObject(Source).FIndex;
    FTemp:=TGraphObject(Source).FTemp;
    FStates:=TGraphObject(Source).FStates;
  end
  else
    Error(SIncompatibleClasses);
end;

{ TGraphElement }

destructor TGraphElement.Destroy;
begin
  FLocal.Free;
  inherited Destroy;
end;

procedure TGraphElement.WriteToStream(VStream: TVStream);
begin
  inherited WriteToStream(VStream);
  if FLocal <> nil then begin
    VStream.WriteInt8(1);
    FLocal.WriteToStream(VStream);
  end
  else
    VStream.WriteInt8(0);
end;

procedure TGraphElement.ReadFromStream(VStream: TVStream);
begin
  inherited ReadFromStream(VStream);
  if VStream.ReadInt8 <> 0 then
    Local.ReadFromStream(VStream)
  else begin
    FLocal.Free;
    FLocal:=nil;
  end;
end;

class function TGraphElement.Compare(Element1, Element2: Pointer): Integer;
var
  B1, B2: Bool;
  Local1, Local2: TAttrSet;
begin
  Result:=CompareUserSets(Element1, Element2);
  if Result = 0 then begin
    Local1:=TGraphElement(Element1).FLocal;
    Local2:=TGraphElement(Element2).FLocal;
    B1:=Local1 <> nil;
    B2:=Local2 <> nil;
    if B1 or B2 then
      if B1 = B2 then
        Result:=CompareUserSets(Local1, Local2)
      else
        if B1 then
          Result:=1
        else
          Result:=-1;
  end;
end;

procedure TGraphElement.Assign(Source: TVector);
begin
  if Source is TGraphElement then begin
    inherited Assign(Source);
    if TGraphElement(Source).FLocal <> nil then
      Local.Assign(TGraphElement(Source).FLocal)
    else begin
      FLocal.Free;
      FLocal:=nil;
    end;
  end
  else
    Error(SIncompatibleClasses);
end;

procedure TGraphElement.Pack;
begin
  inherited Pack;
  if FLocal <> nil then
    FLocal.Pack;
end;

function TGraphElement.HasLocal: Bool;
begin
  Result:=FLocal <> nil;
end;

function TGraphElement.Local: TAttrSet;
begin
  if FLocal = nil then
    FLocal:=TAutoAttrSet.Create;
  Result:=FLocal;
end;

{ TVertex }

constructor TVertex.Create(AGraph: TGraph);
begin
  inherited Create(AGraph.FVertexAttrMap);
  FGraph:=AGraph;
  NeighbEdges:=TClassList.Create;
  AGraph.InsertVertex(Self);
end;

destructor TVertex.Destroy;
var
  I: Integer;
  T: Pointer;
begin
  Include(FStates, gsDestroying);
  if not (gsDestroying in FGraph.FStates) then begin
    if NeighbEdges <> nil then
      for I:=0 to NeighbEdges.Count - 1 do begin
        T:=NeighbEdges[I];
        if T <> nil then begin
          if TEdge(T).IsLoop then begin { ����� ������ ������! }
            NeighbEdges[I]:=nil;
            NeighbEdges[NeighbEdges.IndexOf(T)]:=nil;
          end;
          TObject(T).Free;
        end;
      end;
    FGraph.RemoveVertex(Self);
  end;
  NeighbEdges.Free;
  inherited Destroy;
end;

procedure TVertex.Pack;
begin
  inherited Pack;
  NeighbEdges.Pack;
end;

function TVertex.Degree: Integer;
begin
  Result:=NeighbEdges.Count;
end;

function TVertex.GetNeighbour(I: Integer): TVertex;
begin
  Result:=TEdge(NeighbEdges[I]).OtherVertex(Self);
end;

function TVertex.GetIncidentEdge(I: Integer): TEdge;
begin
  Result:=NeighbEdges[I];
end;

function TVertex.SeparateIndex: Integer;
begin
  FGraph.CheckValidSeparates;
  Result:=AsInt32[GAttrSeparateIndex];
end;

function TVertex.RingVertex: Bool;
var
  I: Integer;
begin
  for I:=0 to NeighbEdges.Count - 1 do
    if TEdge(NeighbEdges[I]).RingEdge then begin
      Result:=True;
      Exit;
    end;
  Result:=False;
end;

procedure TVertex.SortIncidentEdges(CompareEdges: TCompareFunc);
begin
  NeighbEdges.SortBy(CompareEdges);
end;

procedure TVertex.SortIncidentEdgesByObject(CompareEdges: TCompareEvent);
begin
  NeighbEdges.SortByObject(CompareEdges);
end;

{ *** ������� }

function TVertex.InDegree: Integer;
var
  I: Integer;
begin
  {$IFDEF CHECK_GRAPHS}
  if not (Directed in Graph.Features) then Error(SMethodNotApplicable);
  {$ENDIF}
  Result:=0;
  for I:=0 to NeighbEdges.Count - 1 do
    if TEdge(NeighbEdges[I]).V2 = Self then
      Inc(Result);
end;

function TVertex.OutDegree: Integer;
var
  I: Integer;
begin
  {$IFDEF CHECK_GRAPHS}
  if not (Directed in Graph.Features) then Error(SMethodNotApplicable);
  {$ENDIF}
  Result:=0;
  for I:=0 to NeighbEdges.Count - 1 do
    if TEdge(NeighbEdges[I]).V1 = Self then
      Inc(Result);
end;

procedure TVertex.GetInOutDegree(var VertexInDegree, VertexOutDegree: Integer);
var
  I: Integer;
begin
  {$IFDEF CHECK_GRAPHS}
  if not (Directed in Graph.Features) then Error(SMethodNotApplicable);
  {$ENDIF}
  VertexInDegree:=0;
  VertexOutDegree:=0;
  for I:=0 to NeighbEdges.Count - 1 do
    if TEdge(NeighbEdges[I]).V1 = Self then
      Inc(VertexOutDegree)
    else
      Inc(VertexInDegree);
end;

{$IFDEF NOWARN}{$WARNINGS OFF}{$ENDIF}
function TVertex.GetInNeighbour(I: Integer): TVertex;
var
  J, K: Integer;
begin
  {$IFDEF CHECK_GRAPHS}
  if not (Directed in Graph.Features) then Error(SMethodNotApplicable);
  {$ENDIF}
  K:=0;
  for J:=0 to NeighbEdges.Count - 1 do
    if TEdge(NeighbEdges[J]).V2 = Self then begin
      if K = I then begin
        Result:=TEdge(NeighbEdges[J]).V1;
        Exit;
      end;
      Inc(K);
    end;
  ErrorFmt(SArcNotFound_d, [I]);
end;

function TVertex.GetOutNeighbour(I: Integer): TVertex;
var
  J, K: Integer;
begin
  {$IFDEF CHECK_GRAPHS}
  if not (Directed in Graph.Features) then Error(SMethodNotApplicable);
  {$ENDIF}
  K:=0;
  for J:=0 to NeighbEdges.Count - 1 do
    if TEdge(NeighbEdges[J]).V1 = Self then begin
      if K = I then begin
        Result:=TEdge(NeighbEdges[J]).V2;
        Exit;
      end;
      Inc(K);
    end;
  ErrorFmt(SArcNotFound_d, [I]);
end;

function TVertex.GetInArc(I: Integer): TEdge;
var
  J, K: Integer;
begin
  {$IFDEF CHECK_GRAPHS}
  if not (Directed in Graph.Features) then Error(SMethodNotApplicable);
  {$ENDIF}
  K:=0;
  for J:=0 to NeighbEdges.Count - 1 do begin
    Result:=NeighbEdges[J];
    if Result.V2 = Self then begin
      if K = I then
        Exit;
      Inc(K);
    end;
  end;
  ErrorFmt(SVertexNotFound_d, [I]);
end;

function TVertex.GetOutArc(I: Integer): TEdge;
var
  J, K: Integer;
begin
  {$IFDEF CHECK_GRAPHS}
  if not (Directed in Graph.Features) then Error(SMethodNotApplicable);
  {$ENDIF}
  K:=0;
  for J:=0 to NeighbEdges.Count - 1 do begin
    Result:=NeighbEdges[J];
    if Result.V1 = Self then begin
      if K = I then
        Exit;
      Inc(K);
    end;
  end;
  ErrorFmt(SVertexNotFound_d, [I]);
end;
{$IFDEF NOWARN}{$WARNINGS ON}{$ENDIF}

{ *** ������� }

function TVertex.GetIsRoot: Bool;
begin
  {$IFDEF CHECK_GRAPHS}
  if not (Tree in Graph.Features) then Error(SMethodNotApplicable);
  {$ENDIF}
  Result:=TVertex(Graph.AsPointer[GAttrRoot]) = Self;
end;

procedure TVertex.SetIsRoot(Value: Bool);
var
  I: Integer;
  OldRoot: TVertex;
begin
  {$IFDEF CHECK_GRAPHS}
  if not (Tree in Graph.Features) then Error(SMethodNotApplicable);
  {$ENDIF}
  OldRoot:=Graph.AsPointer[GAttrRoot];
  if Value then begin
    Graph.AsPointer[GAttrRoot]:=Self;
    AsBool[GAttrHasParent]:=False;
    for I:=0 to NeighbEdges.Count - 1 do Neighbour[I].Parent:=Self;
  end
  else
    if OldRoot = Self then
      FGraph.AsPointer[GAttrRoot]:=nil;
end;

function TVertex.GetParent: TVertex;
begin
  {$IFDEF CHECK_GRAPHS}
  if not (Tree in Graph.Features) then Error(SMethodNotApplicable);
  {$ENDIF}
  if AsBool[GAttrHasParent] and (NeighbEdges.Count > 0) then
    Result:=Neighbour[0]
  else
    Result:=nil;
end;

procedure TVertex.SafeSetParent(Value: TVertex);
var
  I: Integer;
  E: TEdge;
begin
  if Value <> nil then begin
    E:=FGraph.GetEdge(Value, Self);
    if E = nil then begin
      I:=NeighbEdges.Count;
      FGraph.AddEdge(Value, Self);
    end
    else
      I:=NeighbEdges.IndexOf(E);
    NeighbEdges.Move(I, 0);
    AsBool[GAttrHasParent]:=True;
  end
  else
    AsBool[GAttrHasParent]:=False;
end;

procedure TVertex.SetParent(Value: TVertex);
var
  V: TVertex;
begin
  if not IsRoot then begin
    V:=GetParent;
    if Value <> V then begin
      FGraph.GetEdge(V, Self).Free;
      SafeSetParent(Value);
    end;
  end
  else begin
    if FGraph.GetEdge(Self, Value) = nil then
      Graph.AddEdge(Value, Self);
    Value.IsRoot:=True;
  end;
end;

function TVertex.AddChild: TVertex;
begin
  {$IFDEF CHECK_GRAPHS}
  if not (Tree in Graph.Features) then Error(SMethodNotApplicable);
  {$ENDIF}
  Result:=Graph.AddVertex;
  Result.SafeSetParent(Self);
end;

function TVertex.ChildCount: Integer;
begin
  {$IFDEF CHECK_GRAPHS}
  if not (Tree in Graph.Features) then Error(SMethodNotApplicable);
  {$ENDIF}
  Result:=NeighbEdges.Count;
  if AsBool[GAttrHasParent] then
    Dec(Result);
end;

function TVertex.GetChild(I: Integer): TVertex;
begin
  {$IFDEF CHECK_GRAPHS}
  if not (Tree in Graph.Features) then Error(SMethodNotApplicable);
  {$ENDIF}
  if AsBool[GAttrHasParent] then
    Inc(I);
  Result:=Neighbour[I];
end;

function TVertex.IsAncestorOf(V: TVertex): Bool;
begin
  if V <> Self then
    repeat
      V:=V.Parent;
      if V = nil then begin
        Result:=False;
        Exit;
      end
    until V = Self;
  Result:=True;
end;

procedure TVertex.SortChilds(CompareVertices: TCompareEvent);
var
  I, J: Integer;
  ChildNeighbours, Edges: TClassList;
begin
  if ChildCount = 0 then
    Exit; { ChildCount ���������, ��� ���� - ������ }
  ChildNeighbours:=TClassList.Create;
  Edges:=TClassList.Create;
  try
    Edges.Assign(NeighbEdges);
    J:=0;
    if AsBool[GAttrHasParent] then begin
      Inc(J);
      Edges.Delete(0);
      ChildNeighbours.Count:=NeighbEdges.Count - 1;
    end
    else
      ChildNeighbours.Count:=NeighbEdges.Count;
    for I:=0 to ChildNeighbours.Count - 1 do begin
      ChildNeighbours[I]:=TEdge(NeighbEdges[J]).OtherVertex(Self);
      Inc(J);
    end;
    ChildNeighbours.SortByObjectWith(CompareVertices, Edges);
    J:=0;
    if AsBool[GAttrHasParent] then
      Inc(J);
    for I:=0 to Edges.Count - 1 do begin
      NeighbEdges[J]:=Edges[I];
      Inc(J);
    end;
  finally
    ChildNeighbours.Free;
    Edges.Free;
  end;
end;

{ *** ������������ ���� }

function TVertex.GetIsSource: Bool;
begin
  {$IFDEF CHECK_GRAPHS}
  if not (Network in Graph.Features) then Error(SMethodNotApplicable);
  {$ENDIF}
  Result:=TVertex(Graph.AsPointer[GAttrNetworkSource]) = Self;
end;

procedure TVertex.SetIsSource(Value: Bool);
begin
  {$IFDEF CHECK_GRAPHS}
  if not (Network in Graph.Features) then Error(SMethodNotApplicable);
  {$ENDIF}
  if Value then
    FGraph.AsPointer[GAttrNetworkSource]:=Self
  else
    if FGraph.AsPointer[GAttrNetworkSource] = Self then
      Graph.AsPointer[GAttrNetworkSource]:=nil;
end;

function TVertex.GetIsSink: Bool;
begin
  {$IFDEF CHECK_GRAPHS}
  if not (Network in Graph.Features) then Error(SMethodNotApplicable);
  {$ENDIF}
  Result:=TVertex(Graph.AsPointer[GAttrNetworkSink]) = Self
end;

procedure TVertex.SetIsSink(Value: Bool);
begin
  {$IFDEF CHECK_GRAPHS}
  if not (Network in Graph.Features) then Error(SMethodNotApplicable);
  {$ENDIF}
  if Value then
    FGraph.AsPointer[GAttrNetworkSink]:=Self
  else
    if Graph.AsPointer[GAttrNetworkSink] = Self then
      Graph.AsPointer[GAttrNetworkSink]:=nil;
end;

{ *** �������������� ����� }

function TVertex.GetX: Float;
begin
  {$IFDEF CHECK_GRAPHS}
  if not (Geom2D in Graph.Features) then Error(SMethodNotApplicable);
  {$ENDIF}
  Result:=AsFloat[GAttrX];
end;

procedure TVertex.SetX(Value: Float);
begin
  {$IFDEF CHECK_GRAPHS}
  if not (Geom2D in Graph.Features) then Error(SMethodNotApplicable);
  {$ENDIF}
  AsFloat[GAttrX]:=Value;
end;

function TVertex.GetY: Float;
begin
  {$IFDEF CHECK_GRAPHS}
  if not (Geom2D in Graph.Features) then Error(SMethodNotApplicable);
  {$ENDIF}
  Result:=AsFloat[GAttrY];
end;

procedure TVertex.SetY(Value: Float);
begin
  {$IFDEF CHECK_GRAPHS}
  if not (Geom2D in Graph.Features) then Error(SMethodNotApplicable);
  {$ENDIF}
  AsFloat[GAttrY]:=Value;
end;

function TVertex.GetZ: Float;
begin
  {$IFDEF CHECK_GRAPHS}
  if not (Geom3D in Graph.Features) then Error(SMethodNotApplicable);
  {$ENDIF}
  Result:=AsFloat[GAttrZ];
end;

procedure TVertex.SetZ(Value: Float);
begin
  {$IFDEF CHECK_GRAPHS}
  if not (Geom3D in Graph.Features) then Error(SMethodNotApplicable);
  {$ENDIF}
  AsFloat[GAttrZ]:=Value;
end;

{ TEdge }

constructor TEdge.Create(AGraph: TGraph; FromVertex, ToVertex: TVertex);
begin
  inherited Create(AGraph.FEdgeAttrMap);
  {$IFDEF CHECK_GRAPHS}
  if AGraph.FVertices.IndexOf(FromVertex) < 0 then
    ErrorFmt(SVertexNotFound_d, [FromVertex]);
  if AGraph.FVertices.IndexOf(ToVertex) < 0 then
    ErrorFmt(SVertexNotFound_d, [ToVertex]);
  {$ENDIF}
  FGraph:=AGraph;
  FV1:=FromVertex;
  FV2:=ToVertex;
  V1.NeighbEdges.Add(Self);
  V2.NeighbEdges.Add(Self);
  AGraph.InsertEdge(AGraph.FEdges.Count, Self);
end;

function TEdge.RemoveFromNeighbEdges(V: TVertex): Integer;
begin
  Result:=V.NeighbEdges.IndexOf(Self);
  V.NeighbEdges.Delete(Result);
end;

destructor TEdge.Destroy;
begin
  if Graph <> nil then begin
    Include(FStates, gsDestroying);
    if not (gsDestroying in Graph.FStates) then begin
      if Tree in Graph.FFeatures then
        if V1.AsBool[GAttrHasParent] and (V1.NeighbEdges[0] = Self) then
          V1.AsBool[GAttrHasParent]:=False
        else
          if V2.AsBool[GAttrHasParent] and (V2.NeighbEdges[0] = Self) then
            V2.AsBool[GAttrHasParent]:=False;
      if (V1 <> nil) and not (gsDestroying in V1.FStates) then
        RemoveFromNeighbEdges(V1);
      if (V2 <> nil) and not (gsDestroying in V2.FStates) then
        RemoveFromNeighbEdges(V2);
      Graph.RemoveEdge(Self);
    end;
  end;
  inherited Destroy;
end;

type
  PRestoreInfo = ^TRestoreInfo;
  TRestoreInfo = record
    SaveGraph: TGraph;
    V1Index, V2Index: Integer;
  end;

function TEdge.Hidden: Bool;
begin
  Result:=FGraph = nil;
end;

procedure TEdge.Hide;
var
  RestoreInfo: PRestoreInfo;
begin
  {$IFDEF CHECK_GRAPHS}
  if Hidden then Error(SMethodNotApplicable);
  {$ENDIF}
  New(RestoreInfo);
  With RestoreInfo^ do begin
    SaveGraph:=FGraph;
    V1Index:=RemoveFromNeighbEdges(V1);
    V2Index:=RemoveFromNeighbEdges(V2);
  end;
  FGraph.RemoveEdge(Self);
  FGraph:=nil;
  FTemp.AsPointer:=RestoreInfo;
end;

procedure TEdge.Restore;
begin
  {$IFDEF CHECK_GRAPHS}
  if not Hidden then Error(SMethodNotApplicable);
  {$ENDIF}
  With PRestoreInfo(FTemp.AsPointer)^ do begin
    FGraph:=SaveGraph;
    FGraph.InsertEdge(Index, Self);
    V1.NeighbEdges.Insert(V1Index, Self);
    V2.NeighbEdges.Insert(V2Index, Self);
  end;
  Dispose(PRestoreInfo(FTemp.AsPointer));
end;

function TEdge.EdgeVertices(Vertex1, Vertex2: TVertex): Bool;
begin
  Result:=(V1 = Vertex1) and (V2 = Vertex2) or (V1 = Vertex2) and (V2 = Vertex1);
end;

function TEdge.IncidentToVertex(Vertex: TVertex): Bool;
begin
  Result:=(V1 = Vertex) or (V2 = Vertex);
end;

function TEdge.IncidentToEdgeUndirected(Edge: TEdge): Bool;
begin
  Result:=(V1 = Edge.V1) or (V2 = Edge.V1) or (V1 = Edge.V2) or (V2 = Edge.V2);
end;

function TEdge.IncidentToEdgeDirected(Edge: TEdge): Bool;
begin
  Result:=(V2 = Edge.V1) or (V1 = Edge.V2);
end;

function TEdge.IncidentToEdge(Edge: TEdge): Bool;
begin
  if Directed in Graph.Features then
    Result:=IncidentToEdgeDirected(Edge)
  else
    Result:=IncidentToEdgeUndirected(Edge);
end;

function TEdge.ParallelToEdgeUndirected(Edge: TEdge): Bool;
begin
  Result:=(V1 = Edge.V1) and (V2 = Edge.V2) or (V1 = Edge.V2) and (V2 = Edge.V1);
end;

function TEdge.ParallelToEdgeDirected(Edge: TEdge): Bool;
begin
  Result:=(V1 = Edge.V1) and (V2 = Edge.V2);
end;

function TEdge.ParallelToEdge(Edge: TEdge): Bool;
begin
  Result:=(V1 = Edge.V1) and (V2 = Edge.V2) or
    not (Directed in Graph.Features) and (V1 = Edge.V2) and (V2 = Edge.V1);
end;

function TEdge.OtherVertex(Vertex: TVertex): TVertex;
begin
  if Vertex = V1 then
    Result:=V2
  else
    if Vertex = V2 then
      Result:=V1
    else
      Result:=nil;
end;

function TEdge.IsLoop: Bool;
begin
  Result:=V1 = V2;
end;

function TEdge.RingEdge: Bool;
begin
  if (V1.NeighbEdges.Count = 1) or (V2.NeighbEdges.Count = 1) then
    Result:=False { ������������� ������ ������ ��� ��������� ������������� }
  else begin
    Graph.CheckValidRingEdges;
    Result:=AsBool[GAttrRingEdge];
  end;
end;

{ *** ������������ ���� }

function TEdge.GetMaxFlow: Float;
begin
  {$IFDEF CHECK_GRAPHS}
  if not (Network in Graph.Features) then Error(SMethodNotApplicable);
  {$ENDIF}
  Result:=AsFloat[GAttrMaxFlow];
end;

procedure TEdge.SetMaxFlow(Value: Float);
begin
  {$IFDEF CHECK_GRAPHS}
  if not (Network in Graph.Features) then Error(SMethodNotApplicable);
  {$ENDIF}
  if Value < 0 then
    Error(SNegativeNetworkFlow);
  AsFloat[GAttrMaxFlow]:=Value;
end;

function TEdge.GetFlow: Float;
begin
  {$IFDEF CHECK_GRAPHS}
  if not (Network in Graph.Features) then Error(SMethodNotApplicable);
  {$ENDIF}
  Result:=AsFloat[GAttrFlow];
end;

procedure TEdge.SetFlow(Value: Float);
begin
  {$IFDEF CHECK_GRAPHS}
  if not (Network in Graph.Features) then Error(SMethodNotApplicable);
  {$ENDIF}
  if Value < 0 then
    Error(SNegativeNetworkFlow);
  AsFloat[GAttrFlow]:=Value;
end;

{ *** ���������� ����� }

function TEdge.GetWeight: Float;
begin
  {$IFDEF CHECK_GRAPHS}
  if not (Weighted in Graph.Features) then Error(SMethodNotApplicable);
  {$ENDIF}
  Result:=AsFloat[GAttrWeight];
end;

procedure TEdge.SetWeight(Value: Float);
begin
  {$IFDEF CHECK_GRAPHS}
  if not (Weighted in Graph.Features) then Error(SMethodNotApplicable);
  {$ENDIF}
  AsFloat[GAttrWeight]:=Value;
end;

{ *** ������� }

procedure TEdge.ChangeDirection;
var
  V: TVertex;
begin
  {$IFDEF CHECK_GRAPHS}
  if not (Directed in Graph.Features) then Error(SMethodNotApplicable);
  {$ENDIF}
  V:=FV1; FV1:=FV2; FV2:=V;
end;

{ TGraph }

constructor TGraph.Create;
begin
  inherited Create(TAttrMap.Create);
  FVertices:=TClassList.Create;
  FEdges:=TClassList.Create;
  FVertexAttrMap:=TAttrMap.Create;
  FEdgeAttrMap:=TAttrMap.Create;
end;

procedure TGraph.FreeElements;
var
  I: Integer;
begin
  Include(FStates, gsDestroying);
  for I:=0 to FEdges.Count - 1 do TObject(FEdges[I]).Free;
  for I:=0 to FVertices.Count - 1 do TObject(FVertices[I]).Free;
end;

destructor TGraph.Destroy;
var
  LocalMap: TAttrMap;
begin
  FreeElements;
  FEdges.Free;
  FVertices.Free;
  FVertexAttrMap.Free;
  FEdgeAttrMap.Free;
  LocalMap:=Map;
  inherited Destroy;
  LocalMap.Free;
end;

procedure TGraph.SetStates(NewStates: TGraphObjectStates);
var
  B: Bool;
begin
  B:=gsValidSeparates in FStates;
  if B xor (gsValidSeparates in NewStates) then
    if B then
      SafeDropVertexAttr(GAttrSeparateIndex)
    else
      SafeCreateVertexAttr(GAttrSeparateIndex, AttrInt32);
  B:=gsValidRingEdges in FStates;
  if B xor (gsValidRingEdges in NewStates) then
    if B then
      SafeDropEdgeAttr(GAttrRingEdge)
    else
      SafeCreateEdgeAttr(GAttrRingEdge, AttrBool);
  FStates:=NewStates;
end;

procedure TGraph.WriteToStream(VStream: TVStream);
var
  I, N: Integer;
  E: TEdge;

  procedure WriteIndex(V: TVertex);
  var
    I: Integer;
  begin
    if V <> nil then
      I:=V.Index
    else
      I:=-1;
    VStream.WriteInt32(I);
  end;

begin
  FMap.WriteToStream(VStream);
  FVertexAttrMap.WriteToStream(VStream);
  FEdgeAttrMap.WriteToStream(VStream);
  inherited WriteToStream(VStream);
  VStream.WriteProc(FFeatures, SizeOf(FFeatures));
  VStream.WriteProc(FConnected, SizeOf(FFeatures));
  VStream.WriteProc(FSeparateCount, SizeOf(FFeatures));
  VStream.WriteProc(FRingEdgeCount, SizeOf(FFeatures));
  N:=FVertices.Count;
  VStream.WriteInt32(N);
  for I:=0 to N - 1 do TVertex(FVertices[I]).WriteToStream(VStream);
  N:=FEdges.Count;
  VStream.WriteInt32(N);
  for I:=0 to N - 1 do begin
    E:=FEdges[I];
    WriteIndex(E.V1);
    WriteIndex(E.V2);
    E.WriteToStream(VStream);
  end;
  if Tree in FFeatures then
    WriteIndex(Root);
  if Network in FFeatures then begin
    WriteIndex(NetworkSource);
    WriteIndex(NetworkSink);
  end;
end;

procedure TGraph.ReadFromStream(VStream: TVStream);
var
  I, N, M: Integer;

  function ReadVertex: TVertex;
  var
    K: Integer;
  begin
    K:=VStream.ReadInt32;
    if K <> -1 then
      Result:=FVertices[K]
    else
      Result:=nil;
  end;

begin
  Clear;
  FMap.ReadFromStream(VStream);
  FVertexAttrMap.ReadFromStream(VStream);
  FEdgeAttrMap.ReadFromStream(VStream);
  inherited ReadFromStream(VStream);
  VStream.ReadProc(FFeatures, SizeOf(FFeatures));
  VStream.ReadProc(FConnected, SizeOf(FFeatures));
  VStream.ReadProc(FSeparateCount, SizeOf(FFeatures));
  VStream.ReadProc(FRingEdgeCount, SizeOf(FFeatures));
  N:=VStream.ReadInt32;
  AddVertices(N);
  for I:=0 to N - 1 do TVertex(FVertices[I]).ReadFromStream(VStream);
  for I:=0 to VStream.ReadInt32 - 1 do begin
    N:=VStream.ReadInt32;
    M:=VStream.ReadInt32;
    AddEdgeI(N, M).ReadFromStream(VStream);
  end;
  if Tree in FFeatures then
    Root:=ReadVertex;
  if Network in FFeatures then begin
    NetworkSource:=ReadVertex;
    NetworkSink:=ReadVertex;
  end;
end;

procedure TGraph.Assign(Source: TVector);
var
  I: Integer;
  V: TVertex;
  E: TEdge;
begin
  if Source is TGraph then begin
    Clear;
    FMap.Assign(TGraph(Source).FMap);
    FVertexAttrMap.Assign(TGraph(Source).FVertexAttrMap);
    FEdgeAttrMap.Assign(TGraph(Source).FEdgeAttrMap);
    for I:=0 to TGraph(Source).FVertices.Count - 1 do
      AddVertex.Assign(TGraph(Source).FVertices[I]);
    for I:=0 to TGraph(Source).FEdges.Count - 1 do begin
      E:=TGraph(Source).FEdges[I];
      AddEdgeI(E.V1.Index, E.V2.Index).Assign(E);
    end;
    inherited Assign(Source);
    FConnected:=TGraph(Source).FConnected;
    FSeparateCount:=TGraph(Source).FSeparateCount;
    FRingEdgeCount:=TGraph(Source).FRingEdgeCount;
    SetFeatures(TGraph(Source).FFeatures);
    if Tree in FFeatures then begin
      V:=TGraph(Source).Root;
      if V <> nil then
        SetRoot(FVertices[V.Index]);
    end;
    if Network in FFeatures then begin
      V:=TGraph(Source).NetworkSource;
      if V <> nil then
        SetNetworkSource(FVertices[V.Index]);
      V:=TGraph(Source).NetworkSink;
      if V <> nil then
        SetNetworkSink(FVertices[V.Index]);
    end;
  end
  else
    Error(SIncompatibleClasses);
end;

procedure TGraph.AssignSceleton(Source: TGraph);
var
  I: Integer;
  E: TEdge;
begin
  Clear;
  AddVertices(Source.FVertices.Count);
  for I:=0 to TGraph(Source).FEdges.Count - 1 do begin
    E:=Source.FEdges[I];
    AddEdgeI(E.V1.Index, E.V2.Index);
  end;
end;

procedure TGraph.AssignSimpleSceleton(Source: TGraph);
var
  I, I1, I2: Integer;
  E: TEdge;
begin
  Clear;
  AddVertices(Source.FVertices.Count);
  for I:=0 to TGraph(Source).FEdges.Count - 1 do begin
    E:=Source.FEdges[I];
    I1:=E.V1.Index;
    I2:=E.V2.Index;
    if (I1 <> I2) and (GetEdgeI(I1, I2) = nil) then
      AddEdgeI(I1, I2);
  end;
end;

procedure TGraph.Pack;
var
  I: Integer;
begin
  inherited Pack;
  FVertices.Pack;
  FEdges.Pack;
  for I:=0 to FVertices.Count - 1 do TVertex(FVertices[I]).Pack;
  for I:=0 to FEdges.Count - 1 do TEdge(FEdges[I]).Pack;
end;

procedure TGraph.Clear;
begin
  FreeElements;
  Exclude(FStates, gsDestroying);
  FEdges.Clear;
  FVertices.Clear;
  States:=[];
end;

procedure TGraph.ClearEdges;
begin
  while FEdges.Count > 0 do TEdge(FEdges[0]).Free;
end;

procedure TGraph.InsertVertex(Vertex: TVertex);
begin
  Vertex.FIndex:=FVertices.Add(Vertex);
  States:=States - [gsValidConnected, gsValidSeparates];
end;

procedure TGraph.RemoveVertex(Vertex: TVertex);

  procedure CheckDropAttr(const AttrName: String);
  begin
    if AsPointer[AttrName] = Vertex then
      Map.SafeDropAttr(AttrName);
  end;

var
  I: Integer;
begin
  if Tree in Features then
    CheckDropAttr(GAttrRoot);
  if Network in Features then begin
    CheckDropAttr(GAttrNetworkSource);
    CheckDropAttr(GAttrNetworkSink);
  end;
  FVertices.Delete(Vertex.Index);
  if not (gsDestroying in FStates) then begin
    for I:=Vertex.Index to FVertices.Count - 1 do
      Dec(TVertex(FVertices[I]).FIndex);
    States:=States - [gsValidConnected, gsValidSeparates];
  end;
end;

procedure TGraph.InsertEdge(Index: Integer; Edge: TEdge);
var
  I: Integer;
begin
  FEdges.Insert(Index, Edge);
  Edge.FIndex:=Index;
  for I:=Index + 1 to FEdges.Count - 1 do
    Inc(TEdge(FEdges[I]).FIndex);
  States:=States - [gsValidConnected, gsValidSeparates, gsValidRingEdges];
end;

procedure TGraph.RemoveEdge(Edge: TEdge);
var
  I: Integer;
begin
  FEdges.Delete(Edge.Index);
  if not (gsDestroying in FStates) then begin
    for I:=Edge.Index to FEdges.Count - 1 do
      Dec(TEdge(FEdges[I]).FIndex);
    States:=States - [gsValidConnected, gsValidSeparates, gsValidRingEdges];
    { ������� ��������� ����� => ������ ����� ����� ������������;
      ������� ����������� ����� => ���� ���������� ���� ������� }
  end;
end;

procedure TGraph.SetToZero(List: TClassList; Offset: Integer; AType: TAttrType);
var
  I: Integer;
  ASet: TAttrSet;
begin
  for I:=0 to List.Count - 1 do begin
    ASet:=TAttrSet(List[I]);
    if Offset < ASet.Count then
      FillChar(ASet.Memory^.Int8Array[Offset], AttrSizes[AType], 0);
  end;
end;

function TGraph.CreateVertexAttr(const Name: String; AType: TAttrType): Integer;
begin
  {$IFDEF CHECK_GRAPHS}
  if (Name <> '') and (Name[1] = '.') then Error(SAttrPrefixReserved);
  {$ENDIF}
  Result:=FVertexAttrMap.CreateAttr(Name, AType);
  SetToZero(FVertices, Result, AType);
end;

function TGraph.CreateEdgeAttr(const Name: String; AType: TAttrType): Integer;
begin
  {$IFDEF CHECK_GRAPHS}
  if (Name <> '') and (Name[1] = '.') then Error(SAttrPrefixReserved);
  {$ENDIF}
  Result:=FEdgeAttrMap.CreateAttr(Name, AType);
  SetToZero(FEdges, Result, AType);
end;

procedure TGraph.DropVertexAttr(const Name: String);
begin
  FVertexAttrMap.DropAttr(Name);
end;

procedure TGraph.DropEdgeAttr(const Name: String);
begin
  FEdgeAttrMap.DropAttr(Name);
end;

function TGraph.SafeCreateVertexAttr(const Name: String; AType: TAttrType): Integer;
begin
  Result:=FVertexAttrMap.SafeCreateAttr(Name, AType);
  if Result >= 0 then
    SetToZero(FVertices, Result, AType);
end;

procedure TGraph.SafeDropVertexAttr(const Name: String);
begin
  FVertexAttrMap.SafeDropAttr(Name);
end;

function TGraph.SafeCreateEdgeAttr(const Name: String; AType: TAttrType): Integer;
begin
  Result:=FEdgeAttrMap.SafeCreateAttr(Name, AType);
  if Result >= 0 then
    SetToZero(FEdges, Result, AType);
end;

procedure TGraph.SafeDropEdgeAttr(const Name: String);
begin
  FEdgeAttrMap.SafeDropAttr(Name);
end;

function TGraph.VertexAttrType(const Name: String): TExtAttrType;
begin
  Result:=FVertexAttrMap.GetType(Name);
end;

function TGraph.EdgeAttrType(const Name: String): TExtAttrType;
begin
  Result:=FEdgeAttrMap.GetType(Name);
end;

function TGraph.VertexAttrOffset(const Name: String): Integer;
begin
  Result:=FVertexAttrMap.Offset(Name);
end;

function TGraph.EdgeAttrOffset(const Name: String): Integer;
begin
  Result:=FEdgeAttrMap.Offset(Name);
end;

function TGraph.VertexCount: Integer;
begin
  Result:=FVertices.Count;
end;

function TGraph.EdgeCount: Integer;
begin
  Result:=FEdges.Count;
end;

function TGraph.GetVertex(I: Integer): TVertex;
begin
  Result:=TVertex(FVertices[I]);
end;

function TGraph.GetEdgeByIndex(I: Integer): TEdge;
begin
  Result:=FEdges[I];
end;

function TGraph.AddVertex: TVertex;
begin
  Result:=TVertex.Create(Self);
end;

procedure TGraph.AddVertices(ACount: Integer);
var
  I: Integer;
begin
  FVertices.Capacity:=FVertices.Count + ACount;
  for I:=1 to ACount do TVertex.Create(Self);
end;

function TGraph.AddEdge(Vertex1, Vertex2: TVertex): TEdge;
begin
  Result:=TEdge.Create(Self, Vertex1, Vertex2);
end;

function TGraph.AddEdgeI(I1, I2: Integer): TEdge;
begin
  Result:=TEdge.Create(Self, Vertices[I1], Vertices[I2]);
end;

procedure TGraph.AddEdges(const VertexIndexes: array of Integer);
var
  I: Integer;
begin
  I:=0;
  repeat
    TEdge.Create(Self,
      FVertices[VertexIndexes[I]],
      FVertices[VertexIndexes[I + 1]]);
    Inc(I, 2);
  until I > High(VertexIndexes);
end;

procedure TGraph.GetSeparateOf(Source: TGraph; V: TVertex);
var
  I: Integer;
  U: TVertex;
  E: TEdge;
begin
  {$IFDEF CHECK_GRAPHS}
  if Source = Self then Error(SErrorInParameters);
  {$ENDIF}
  Clear;
  Source.BFSFromVertex(V);
  for I:=0 to Source.VertexCount - 1 do begin
    V:=Source.FVertices[I];
    if V.FTemp.AsInt32 >= 0 then begin
      U:=AddVertex;
      U.FTemp.AsInt32:=V.Index;
      V.FTemp.AsInt32:=U.Index;
    end;
  end;
  for I:=0 to Source.EdgeCount - 1 do begin
    E:=Source.FEdges[I];
    if E.V1.FTemp.AsInt32 >= 0 then
      AddEdgeI(E.V1.FTemp.AsInt32, E.V2.FTemp.AsInt32);
  end;
end;

{$IFDEF NOWARN}{$WARNINGS OFF}{$ENDIF}
function TGraph.FFindMinPathCond(Vertex1, Vertex2: TVertex;
  AcceptVertex: TAcceptVertex; AcceptEdge: TAcceptEdge;
  EdgePath: TClassList): Integer;
{ "��������" �������� ������ ���� ����������� ����� }
var
  I: Integer;
  Found: Bool;
  V: TVertex;
  E: TEdge;
  Front, OldFront, T: TClassList;

  procedure AddToFront(AVertex: TVertex);
  var
    I: Integer;
    V: TVertex;
    E: TEdge;
  begin
    for I:=0 to AVertex.NeighbEdges.Count - 1 do begin
      E:=AVertex.NeighbEdges[I];
      if not Assigned(AcceptEdge) or AcceptEdge(E, AVertex) then begin
        V:=E.OtherVertex(AVertex);
        if V <> Vertex2 then begin
          { ������� �� ������ ����� ��������� � �� �������� => �������� }
          if (V.FTemp.AsPointer = nil) and
            (not Assigned(AcceptVertex) or AcceptVertex(V))
          then
            Front.Add(E);
        end
        else begin
          Front.Clear;
          V.FTemp.AsPointer:=E;
          Found:=True;
          Exit;
        end;
      end;
    end;
  end;

begin
  if not (gsValidSeparates in FStates) or
    (Vertex1.SeparateIndex = Vertex2.SeparateIndex) then
  begin
    SetTempForVertices(Int32(nil));
    Front:=TClassList.Create;
    OldFront:=TClassList.Create;
    try
      Vertex1.FTemp.AsPointer:=Vertex1; { ����� ��-nil ��������� }
      Result:=1;
      Found:=False;
      AddToFront(Vertex1);
      if not Found then
        while Front.Count > 0 do begin
          Inc(Result);
          T:=OldFront;
          OldFront:=Front;
          Front:=T;
          Front.Clear;
          { ��� ��������� ��������� }
          for I:=0 to OldFront.Count - 1 do begin
            E:=OldFront[I];
            { �������� ������ ����� ����� (����) ��� ����������� }
            if E.V1.FTemp.AsPointer = nil then
              V:=E.V1
            else
              if E.V2.FTemp.AsPointer = nil then
                V:=E.V2
              else
                Continue; { ��� �������� ��� ������� ����� }
            V.FTemp.AsPointer:=E;
            AddToFront(V);
            if Found then { ����� }
              Break;
          end;
        end;
      if Found then begin { �������� ��� }
        if EdgePath <> nil then begin
          for I:=0 to Result - 1 do begin
            E:=Vertex2.FTemp.AsPointer;
            EdgePath.Add(E);
            Vertex2:=E.OtherVertex(Vertex2);
          end;
          EdgePath.Pack;
          EdgePath.Reverse;
        end;
      end
      else
        Result:=-1;
    finally
      Front.Free;
      OldFront.Free;
    end;
  end
  else
    Result:=-1;
end;

procedure TGraph.SetTempForVertices(Value: Int32);
var
  I: Integer;
begin
  for I:=0 to FVertices.Count - 1 do
    TVertex(FVertices[I]).FTemp.AsInt32:=Value;
end;

procedure TGraph.SetTempForEdges(Value: Int32);
var
  I: Integer;
begin
  for I:=0 to FEdges.Count - 1 do
    TEdge(FEdges[I]).FTemp.AsInt32:=Value;
end;

procedure TGraph.SetTempFromVertex(V: TVertex; Value: Int32);
var
  I, J: Integer;
  V1, V2: TVertex;
  E: TEdge;
  Front, OldFront, T: TClassList;
begin
  SetTempForEdges(-1);
  Front:=TClassList.Create;
  OldFront:=TClassList.Create;
  try
    V.FTemp.AsInt32:=Value;
    OldFront.Add(V);
    repeat
      for I:=0 to OldFront.Count - 1 do begin
        V1:=OldFront[I];
        for J:=0 to V1.NeighbEdges.Count - 1 do begin
          E:=V1.NeighbEdges[J];
          if E.FTemp.AsInt32 <> 0 then begin
            V2:=E.OtherVertex(V1);
            V2.FTemp.AsInt32:=Value;
            Front.Add(V2);
            E.FTemp.AsInt32:=0;
          end;
        end;
      end;
      T:=OldFront;
      OldFront:=Front;
      Front:=T;
      Front.Clear;
    until OldFront.Count = 0;
  finally
    Front.Free;
    OldFront.Free;
  end;
end;

function TGraph.DFSFromVertex(V: TVertex): Integer;
label L1, L2;
var
  I: Integer;
  Neighbour: TVertex;
  S1: TPointerStack;
  S2: TIntegerStack;
begin
  SetTempForVertices(-1);
  Result:=0;
  S1:=TPointerStack.Create;
  S2:=TIntegerStack.Create;
  try
  L1:
    V.FTemp.AsInt32:=Result;
    Inc(Result);
    I:=0;
  L2:
    while I < V.NeighbEdges.Count do begin
      Neighbour:=V.Neighbour[I];
      Inc(I);
      if Neighbour.FTemp.AsInt32 < 0 then begin
        S1.Push(V);
        S2.Push(I);
        V:=Neighbour;
        goto L1;
      end;
    end;
    if S1.Count > 0 then begin
      V:=S1.Pop;
      I:=S2.Pop;
      goto L2;
    end;
  finally
    S1.Free;
    S2.Free;
  end;
end;

function TGraph.BFSFromVertex(V: TVertex): Integer;
begin
  Result:=BFSTraversal(V, nil);
end;

function TGraph.BFSTraversal(V: TVertex; VisitProc: TVisitProc): Integer;
var
  I, J, Time: Integer;
  V1, V2: TVertex;
  Front, OldFront, T: TClassList;
begin
  SetTempForVertices(-1);
  Result:=1;
  Front:=TClassList.Create;
  OldFront:=TClassList.Create;
  try
    V.FTemp.AsInt32:=0;
    OldFront.Add(V);
    Time:=1;
    repeat
      for I:=0 to OldFront.Count - 1 do begin
        V1:=OldFront[I];
        for J:=0 to V1.NeighbEdges.Count - 1 do begin
          V2:=TEdge(V1.NeighbEdges[J]).OtherVertex(V1);
          if V2.FTemp.AsInt32 = -1 then begin
            V2.FTemp.AsInt32:=Time;
            Inc(Result);
            Front.Add(V2);
            if Assigned(VisitProc) then
              VisitProc(V2);
          end;
        end; {for}
      end; {for}
      Inc(Time);
      T:=OldFront;
      OldFront:=Front;
      Front:=T;
      Front.Clear;
    until OldFront.Count = 0;
  finally
    Front.Free;
    OldFront.Free;
  end;
end;

function TGraph.BFSFromVertexFindMeetings(V: TVertex; VertexMeetings,
  EdgeMeetings: TClassList): Integer;
var
  I, J, Time: Integer;
  V1, V2: TVertex;
  Front, OldFront, T: TClassList;
begin
  if Assigned(VertexMeetings) then
    VertexMeetings.Clear;
  if Assigned(EdgeMeetings) then
    EdgeMeetings.Clear;
  SetTempForVertices(-1);
  Result:=1;
  Front:=TClassList.Create;
  OldFront:=TClassList.Create;
  try
    V.FTemp.AsInt32:=0;
    OldFront.Add(V);
    Time:=1;
    repeat
      for I:=0 to OldFront.Count - 1 do begin
        V1:=OldFront[I];
        for J:=0 to V1.NeighbEdges.Count - 1 do begin
          V2:=TEdge(V1.NeighbEdges[J]).OtherVertex(V1);
          if V2.FTemp.AsInt32 = -1 then begin
            V2.FTemp.AsInt32:=Time;
            Inc(Result);
            Front.Add(V2);
          end
          else { ���������� ����� ������ �� �������� / ������ }
            if Assigned(VertexMeetings) then
              if V2.FTemp.AsInt32 = Time then
                VertexMeetings.Add(V2)
              else
                if Assigned(EdgeMeetings) then
                  if (V2.FTemp.AsInt32 = Time - 1) and (V1.Index < V2.Index) then
                    EdgeMeetings.Add(V1.NeighbEdges[J]);
        end; {for}
      end; {for}
      Inc(Time);
      T:=OldFront;
      OldFront:=Front;
      Front:=T;
      Front.Clear;
    until OldFront.Count = 0;
  finally
    Front.Free;
    OldFront.Free;
  end;
  if Assigned(VertexMeetings) then
    VertexMeetings.Pack;
  if Assigned(EdgeMeetings) then
    EdgeMeetings.Pack;
  {$IFDEF CHECK_GRAPHS} { ����������� }
  if Assigned(VertexMeetings) and Assigned(EdgeMeetings) and Connected and
    (CyclomaticNumber <> VertexMeetings.Count + EdgeMeetings.Count + LoopCount)
  then
    Error(SAlgorithmFailure);
  {$ENDIF}
end;

procedure TGraph.BFSFromVertexDirected(V: TVertex);
var
  I, J, Time: Integer;
  V1, V2: TVertex;
  E: TEdge;
  Front, OldFront, T: TClassList;
begin
  SetTempForVertices(-1);
  Front:=TClassList.Create;
  OldFront:=TClassList.Create;
  try
    V.FTemp.AsInt32:=0;
    OldFront.Add(V);
    Time:=1;
    repeat
      for I:=0 to OldFront.Count - 1 do begin
        V1:=OldFront[I];
        for J:=0 to V1.NeighbEdges.Count - 1 do begin
          E:=V1.NeighbEdges[J];
          if E.V1 = V1 then begin
            V2:=E.V2;
            if V2.FTemp.AsInt32 = -1 then begin
              V2.FTemp.AsInt32:=Time;
              Front.Add(V2);
            end;
          end;
        end;
      end;
      Inc(Time);
      T:=OldFront;
      OldFront:=Front;
      Front:=T;
      Front.Clear;
    until OldFront.Count = 0;
  finally
    Front.Free;
    OldFront.Free;
  end;
end;

function TGraph.FindMinPathCond(Vertex1, Vertex2: TVertex;
  AcceptVertex: TAcceptVertex; AcceptEdge: TAcceptEdge;
  EdgePath: TClassList): Integer;
begin
  if EdgePath <> nil then
    EdgePath.Clear;
  if Vertex1 <> Vertex2 then
    Result:=FFindMinPathCond(Vertex1, Vertex2, AcceptVertex, AcceptEdge, EdgePath)
  else
    Result:=0;
end;

function TGraph.FindMinPathUndirected(Vertex1, Vertex2: TVertex;
  EdgePath: TClassList): Integer;
begin
  Result:=FindMinPathCond(Vertex1, Vertex2, nil, nil, EdgePath);
end;

function TGraph.AcceptArc(Edge: TEdge; FromVertex: TVertex): Bool;
begin
  Result:=Edge.V1 = FromVertex;
end;

function TGraph.FindMinPathDirected(Vertex1, Vertex2: TVertex;
  EdgePath: TClassList): Integer;
begin
  Result:=FindMinPathCond(Vertex1, Vertex2, nil, AcceptArc, EdgePath)
end;

function TGraph.FindMinPath(Vertex1, Vertex2: TVertex;
  EdgePath: TClassList): Integer;
begin
  if Directed in Features then
    Result:=FindMinPathCond(Vertex1, Vertex2, nil, AcceptArc, EdgePath)
  else
    Result:=FindMinPathCond(Vertex1, Vertex2, nil, nil, EdgePath);
end;

function TGraph.FFindMinPaths(Vertex1, Vertex2: TVertex; SolutionCount: Integer;
  EdgePaths: TMultiList; DirectedGraph: Bool): Integer;
Label Next;
var
  I, J, K, Time: Integer;
  P: Pointer;
  V, Neighbour: TVertex;
  E: TEdge;
  Front, OldFront, T: TClassList;
  NewEdgePaths, NewEdgePathsRef, OldEdgePaths: TMultiList;
begin
  Result:=0;
  EdgePaths.Clear;
  if not (gsValidSeparates in FStates) or
    (Vertex1.SeparateIndex = Vertex2.SeparateIndex) then
  begin
    Vertex2.FTemp.AsInt32:=-1;
    if DirectedGraph then
      BFSFromVertexDirected(Vertex1)
    else
      BFSFromVertex(Vertex1);
    Time:=Vertex2.FTemp.AsInt32;
    if Time > 0 then begin
      EdgePaths.Grow(1);
      OldEdgePaths:=EdgePaths;
      Front:=TClassList.Create;
      OldFront:=TClassList.Create;
      NewEdgePaths:=TMultiList.Create(TClassList);
      NewEdgePathsRef:=NewEdgePaths;
      try
        OldFront.Add(Vertex2);
        repeat
          Dec(Time);
          for I:=0 to OldFront.Count - 1 do begin
            V:=OldFront[I];
            for J:=0 to V.NeighbEdges.Count - 1 do begin
              E:=V.NeighbEdges[J];
              if DirectedGraph then
                if E.V2 = V then
                  Neighbour:=E.V1
                else
                  Continue
              else
                Neighbour:=E.OtherVertex(V);
              if Neighbour.FTemp.AsInt32 = Time then begin
                if Front.IndexOf(Neighbour) < 0 then
                  Front.Add(Neighbour);
                for K:=0 to OldEdgePaths.Count - 1 do begin
                  T:=OldEdgePaths[K];
                  if (T.Count = 0) or TEdge(T.Last).IncidentToEdgeUndirected(E) then begin
                    NewEdgePaths.AddAssign(T);
                    NewEdgePaths.Last.Add(E);
                    if NewEdgePaths.Count = SolutionCount then
                      goto Next;
                  end;
                end; {for K}
              end;
            end; {for J}
          end; {for I}
        Next:
          P:=OldEdgePaths;
          OldEdgePaths:=NewEdgePaths;
          NewEdgePaths:=TMultiList(P);
          NewEdgePaths.Clear;
          T:=OldFront;
          OldFront:=Front;
          Front:=T;
          Front.Clear;
        until Time = 0;
        if OldEdgePaths <> EdgePaths then
          EdgePaths.Assign(OldEdgePaths);
        Result:=EdgePaths.Count;
        for I:=0 to Result - 1 do With EdgePaths[I] do begin
          Pack;
          Reverse;
        end;
      finally
        Front.Free;
        OldFront.Free;
        NewEdgePathsRef.Free;
      end;
    end;
  end;
end;

function TGraph.FindMinPathsUndirected(Vertex1, Vertex2: TVertex;
  SolutionCount: Integer; EdgePaths: TMultiList): Integer;
begin
  Result:=FFindMinPaths(Vertex1, Vertex2, SolutionCount, EdgePaths, False);
end;

function TGraph.FindMinPathsDirected(Vertex1, Vertex2: TVertex;
  SolutionCount: Integer; EdgePaths: TMultiList): Integer;
begin
  Result:=FFindMinPaths(Vertex1, Vertex2, SolutionCount, EdgePaths, True);
end;

function TGraph.FindMinPaths(Vertex1, Vertex2: TVertex; SolutionCount: Integer;
  EdgePaths: TMultiList): Integer;
begin
  Result:=FFindMinPaths(Vertex1, Vertex2, SolutionCount, EdgePaths,
    Directed in Features);
end;

type
  PRingData = ^TRingData;
  TRingData = record
    Prohibited: TEdge;
    UserAcceptEdge: TAcceptEdge;
  end;

function TGraph.FindMinRingAcceptEdge(Edge: TEdge; FromVertex: TVertex): Bool;
begin
  With PRingData(FTemp.AsPointer)^ do
    Result:=(Edge <> Prohibited) and
      (not Assigned(UserAcceptEdge) or UserAcceptEdge(Edge, FromVertex));
end;

function TGraph.FFindMinRingCond(Vertex: TVertex; AcceptVertex: TAcceptVertex;
  AcceptEdge: TAcceptEdge; EdgePath: TClassList): Integer;
var
  I, PathLength: Integer;
  RingFound: Bool;
  V: TVertex;
  E: TEdge;
  T: TClassList;
  RingData: TRingData;
begin
  if EdgePath <> nil then
    T:=TClassList.Create
  else
    T:=nil;
  try
    RingData.UserAcceptEdge:=AcceptEdge;
    FTemp.AsPointer:=@RingData;
    RingFound:=False;
    Result:=MaxInt;
    for I:=0 to Vertex.NeighbEdges.Count - 1 do begin
      { ��������� ���� �� ��� }
      E:=Vertex.NeighbEdges[I];
      if not Assigned(AcceptEdge) or AcceptEdge(E, Vertex) then begin
        V:=E.OtherVertex(Vertex);
        if V = Vertex then begin { ����� }
          if EdgePath <> nil then begin
            EdgePath.Count:=1;
            EdgePath[0]:=E;
          end;
          Result:=1;
          Exit;
        end;
        RingData.Prohibited:=E;
        PathLength:=FFindMinPathCond(Vertex, V, AcceptVertex,
          FindMinRingAcceptEdge, T);
        if (PathLength > 0) and (PathLength < Result) then begin
          RingFound:=True;
          Result:=PathLength;
          if EdgePath <> nil then begin
            EdgePath.Assign(T);
            EdgePath.Add(E);
            EdgePath.Pack;
          end;
        end;
        if T <> nil then
          T.Clear;
      end;
    end;
    if RingFound then
      Inc(Result)
    else
      Result:=-1;
  finally
    T.Free;
  end;
end;

function TGraph.FindMinRingCond(Vertex: TVertex;
  AcceptVertex: TAcceptVertex; AcceptEdge: TAcceptEdge;
  EdgePath: TClassList): Integer;
begin
  if EdgePath <> nil then
    EdgePath.Clear;
  if Directed in Features then
    Result:=FFindMinPathCond(Vertex, Vertex, AcceptVertex, AcceptEdge, EdgePath)
  else
    Result:=FFindMinRingCond(Vertex, AcceptVertex, AcceptEdge, EdgePath);
end;

function TGraph.FindMinRing(Vertex: TVertex; EdgePath: TClassList): Integer;
begin
  if Directed in Features then
    Result:=FindMinRingCond(Vertex, nil, AcceptArc, EdgePath)
  else
    Result:=FindMinRingCond(Vertex, nil, nil, EdgePath);
end;
{$IFDEF NOWARN}{$WARNINGS ON}{$ENDIF}

function TGraph.CreateRingDegreesVector: TIntegerVector;
var
  I, J, Counter: Integer;
  E: TEdge;
  NeighbEdges: TClassList;
  OldFeatures: TGraphFeatures;
begin
  Result:=TIntegerVector.Create(FVertices.Count, 0);
  try
    OldFeatures:=Features;
    try
      Features:=OldFeatures - [Directed];
      for I:=0 to FVertices.Count - 1 do begin
        Counter:=0;
        NeighbEdges:=TVertex(FVertices[I]).NeighbEdges;
        for J:=0 to NeighbEdges.Count - 1 do begin
          E:=NeighbEdges[J];
          if E.V1 <> E.V2 then
            Inc(Counter, Ord(E.RingEdge)); { ����� �� ��������� }
        end;
        Result[I]:=Counter;
      end;
    finally
      Features:=OldFeatures;
    end;
  except
    Result.Free;
    raise;
  end;
end;

{ ��������������� ����� ��� ������ ����� (������ �� ����������� �������������:
  ����� �� ��������� ������� ������� ��� ������ ������ FFindRingsFromEdge ��
  FindMinRingCovering) }
type
  TFindRingFromEdgeHelper = class
    Graph: TGraph;
    SingleTrueIndexes: TIntegerVector;
    EdgePath, NewRing, CorrectedRings: TClassList;
    NewRings: TMultiList;
    NewRingCode, Sum, ProhibitedColumns: TBoolVector;
    constructor Create(AGraph: TGraph);
    destructor Destroy; override;
    procedure CheckRing(Rings: TMultiList);
  end;

constructor TFindRingFromEdgeHelper.Create(AGraph: TGraph);
begin
  inherited Create;
  Graph:=AGraph;
  SingleTrueIndexes:=TIntegerVector.Create(0, 0);
  EdgePath:=TClassList.Create;
  NewRing:=TClassList.Create;
  CorrectedRings:=TClassList.Create;
  NewRings:=TMultiList.Create(TClassList);
  NewRingCode:=TPackedBoolVector.Create(AGraph.FEdges.Count, False);
  Sum:=TPackedBoolVector.Create(AGraph.FEdges.Count, False);
  ProhibitedColumns:=TBoolVector.Create(AGraph.FEdges.Count, False);
end;

destructor TFindRingFromEdgeHelper.Destroy;
begin
  SingleTrueIndexes.Free;
  EdgePath.Free;
  NewRing.Free;
  CorrectedRings.FreeItems;
  CorrectedRings.Free;
  NewRings.Free;
  NewRingCode.Free;
  Sum.Free;
  ProhibitedColumns.Free;
  inherited Destroy;
end;

{$IFDEF NOWARN}{$WARNINGS OFF}{$ENDIF}
procedure TFindRingFromEdgeHelper.CheckRing(Rings: TMultiList);
{ ���������, ��� ��������� ������ EdgePath �� ������� ������������ ���
  ��������� ����������� ����� Rings �, ���� ��, �� ��������� EdgePath
  � Rings; ���������� True, ���� ������� MaxRings �����, ����� False }

  procedure StandardizeRing;
  { �������� ������ EdgePath � ������ ������������ ���� NewRing }
  var
    RingStart: Integer;

    function NextRingIndex(ADir: Integer): Integer;
    begin
      Result:=RingStart + ADir;
      if Result >= EdgePath.Count then
        Result:=0
      else
        if Result < 0 then
          Result:=EdgePath.Count - 1;
    end;

  var
    I, N, MinIndex, Dir: Integer;
    E1, E2: TEdge;
  begin {StandardizeRing}
    { ��������� ������ ����� ������� ����� � ����������� �������� }
    MinIndex:=MaxInt;
    N:=EdgePath.Count;
    for I:=0 to N - 1 do begin
      E1:=EdgePath[I];
      if E1.Index < MinIndex then begin
        RingStart:=I;
        MinIndex:=E1.Index;
      end;
    end;
    { ���������� ����������� ������ �� ����������� ������� }
    E1:=EdgePath[NextRingIndex(1)];
    E2:=EdgePath[NextRingIndex(-1)];
    if (E1.Index < E2.Index) or (E1.Index = E2.Index) and (E1.Index < E2.Index)
    then
      Dir:=1
    else
      Dir:=-1;
    { ������� EdgePath � "��������" NewRing }
    NewRing.Count:=N;
    for I:=0 to N - 1 do begin
      NewRing[I]:=EdgePath[RingStart];
      RingStart:=NextRingIndex(Dir);
    end;
    EdgePath.Clear;
  end; {StandardizeRing}

  function IndependentRing: Bool;
  { ���������� True, ���� ������ NewRing �� ������� �� ����� Rings, �
    False - ����� }
  var
    I, J: Integer;
    T: TBoolVector;
  begin
    { ������������ NewRing � ���� ��������� ������� }
    for I:=0 to NewRing.Count - 1 do
      NewRingCode[TEdge(NewRing[I]).Index]:=True;
    { ��������� ������������� }
    Sum.SetToDefault;
    for I:=0 to SingleTrueIndexes.Count - 1 do
      if NewRingCode[SingleTrueIndexes[I]] then
        Sum.XorVector(TBoolVector(CorrectedRings[I]));
    if Sum.EqualTo(NewRingCode) then begin
      NewRingCode.SetToDefault;
      Result:=False;
      Exit;
    end;
    { ��������� CorrectedRings, SingleTrueIndexes � ProhibitedColumns }
    NewRingCode.XorVector(Sum);
    for I:=0 to NewRingCode.Count - 1 do
      if not ProhibitedColumns[I] and NewRingCode[I] then begin
        for J:=0 to CorrectedRings.Count - 1 do begin
          T:=TBoolVector(CorrectedRings[J]);
          if T[I] then
            T.XorVector(NewRingCode);
        end;
        SingleTrueIndexes.Add(I);
        ProhibitedColumns[I]:=True;
        Break;
      end;
    CorrectedRings.Add(NewRingCode);
    NewRingCode:=TPackedBoolVector.Create(Graph.FEdges.Count, False);
    Result:=True;
  end; {IndependentRing}

var
  I: Integer;
begin {CheckRing}
  { �������� ������ � ������������ ���� }
  StandardizeRing;
  { ���� ������ ���� ������� �����, �� ������� }
  for I:=0 to Rings.Count - 1 do
    if Rings[I].EqualTo(NewRing) then
      Exit;
  { ���� ������ ������� �� ��������� �����, �� ������� }
  if not IndependentRing then
    Exit;
  { ��������� ������ � ������ ��������� ����������� ����� }
  Rings.AddAssign(NewRing);
end; {CheckRing}
{$IFDEF NOWARN}{$WARNINGS ON}{$ENDIF}

procedure TGraph.FFindRingsFromEdge(FromEdge: TEdge; Rings: TMultiList;
  MaxRings: Integer; FindRingFromEdgeHelper: Pointer);
var
  I: Integer;
begin
  With TFindRingFromEdgeHelper(FindRingFromEdgeHelper) do begin
    FromEdge.Hide;
    try
      FindMinPathsUndirected(FromEdge.V1, FromEdge.V2, -1, NewRings);
    finally
      FromEdge.Restore;
    end;
    for I:=0 to NewRings.Count - 1 do begin
      EdgePath.Assign(NewRings[I]);
      NewRings[I]:=nil;
      EdgePath.Add(FromEdge);
      CheckRing(Rings);
      { ��������� ���������� ��������� ����� }
      if Rings.Count >= MaxRings then
        Exit;
    end;
  end;
end;

function TGraph.FindRingsFromEdge(FromEdge: TEdge; Rings: TMultiList;
  MaxRings: Integer): Integer;
var
  FindRingFromEdgeHelper: TFindRingFromEdgeHelper;
begin
  Rings.Clear;
  FindRingFromEdgeHelper:=TFindRingFromEdgeHelper.Create(Self);
  try
    FFindRingsFromEdge(FromEdge, Rings, MaxRings, FindRingFromEdgeHelper);
  finally
    FindRingFromEdgeHelper.Free;
  end;
  Result:=Rings.Count;
end;

function TGraph.FindMinRingCovering(Rings: TMultiList): Integer;
var
  I, CyclesNumber: Integer;
  RingEdges: TBoolVector;
  FindRingFromEdgeHelper: TFindRingFromEdgeHelper;
  OldFeatures: TGraphFeatures;
begin
  Rings.Clear;
  CyclesNumber:=CyclomaticNumber - LoopCount;
  if CyclesNumber > 0 then begin
    FindRingFromEdgeHelper:=TFindRingFromEdgeHelper.Create(Self);
    RingEdges:=nil;
    OldFeatures:=Features;
    try
      Features:=OldFeatures - [Directed];
      { ��� ������ FFindRingsFromEdge ������������ ������ TEdge.Hide /
        TEdge.Restore, ������� ���������� ���������� � �������������� ����� �
        �������, ������� ��� ��������� ������������� ���������� ��� ���������� }
      RingEdges:=TBoolVector.Create(FEdges.Count, False);
      for I:=0 to FEdges.Count - 1 do
        if TEdge(FEdges[I]).RingEdge then
          RingEdges[I]:=True;
      { �������� ���� }
      for I:=0 to FEdges.Count - 1 do
        if RingEdges[I] then begin
          FFindRingsFromEdge(TEdge(FEdges[I]), Rings, CyclesNumber,
            FindRingFromEdgeHelper);
          if Rings.Count >= CyclesNumber then
            Break;
        end;
      {$IFDEF CHECK_GRAPHS} { ����������� }
      if not CompleteRingSystem(Rings) then
        Error(SAlgorithmFailure);
      {$ENDIF}
    finally
      FindRingFromEdgeHelper.Free;
      RingEdges.Free;
      Features:=OldFeatures;
    end;
  end;
  Result:=Rings.Count;
end;

function TGraph.CompleteRingSystem(Rings: TMultiList): Bool;
var
  I, J: Integer;
  E: TEdge;
  T: TBoolVector;
  Ring: TClassList;
begin
  T:=TBoolVector.Create(FEdges.Count, False);
  try
    for I:=0 to Rings.Count - 1 do begin
      Ring:=Rings[I];
      for J:=0 to Ring.Count - 1 do
        T[TEdge(Ring[J]).Index]:=True;
    end;
    for I:=0 to FEdges.Count - 1 do begin
      E:=FEdges[I];
      if (E.V1 <> E.V2) and E.RingEdge and not T[E.Index] then begin
        Result:=False;
        Exit;
      end;
    end;
    Result:=True;
  finally
    T.Free;
  end;
end;

function TEdgeFilter.AcceptEdge(Edge: TEdge; FromVertex: TVertex): Bool;
begin
  Result:=AllowedEdges[Edge.Index];
end;

constructor TAutoEdgeFilter.Create(EdgeCount: Integer);
begin
  inherited Create;
  AllowedEdges:=TBoolVector.Create(EdgeCount, True);
end;

destructor TAutoEdgeFilter.Destroy;
begin
  AllowedEdges.Free;
  inherited Destroy;
end;

function TGraph.FindSpanningTree(EdgeInST: TBoolVector; STEdges: TClassList): Integer;
var
  I: Integer;
  E: TEdge;
  EdgeFilter: TEdgeFilter;
begin
  Result:=0;
  EdgeFilter:=TEdgeFilter.Create;
  if EdgeInST <> nil then begin
    EdgeInST.Count:=FEdges.Count;
    EdgeInST.FillValue(False);
    EdgeFilter.AllowedEdges:=EdgeInST;
  end
  else
    EdgeFilter.AllowedEdges:=TBoolVector.Create(FEdges.Count, False);
  try
    if STEdges <> nil then
      STEdges.Count:=FEdges.Count;
    for I:=0 to FEdges.Count - 1 do begin
      E:=FEdges[I];
      if FindMinPathCond(E.V1, E.V2, nil, EdgeFilter.AcceptEdge, nil) < 0 then begin
        EdgeFilter.AllowedEdges[I]:=True;
        if STEdges <> nil then
          STEdges[Result]:=E;
        Inc(Result);
      end;
    end;
  finally
    if EdgeInST = nil then
      EdgeFilter.AllowedEdges.Free;
    EdgeFilter.Free;
  end;
  if STEdges <> nil then
    STEdges.Count:=Result;
end;

function TGraph.FindFundamentalRings(Rings: TMultiList): Integer;
var
  I: Integer;
  E: TEdge;
  Ring: TClassList;
  EdgeFilter: TEdgeFilter;
begin
  Rings.Clear;
  EdgeFilter:=TAutoEdgeFilter.Create(0);
  try
    FindSpanningTree(EdgeFilter.AllowedEdges, nil);
    for I:=0 to FEdges.Count - 1 do
      if not EdgeFilter.AllowedEdges[I] then begin
        E:=FEdges[I];
        if not E.IsLoop then begin
          Rings.Grow(1);
          Ring:=Rings.Last;
          FindMinPathCond(E.V1, E.V2, nil, EdgeFilter.AcceptEdge, Ring);
          Ring.Add(E);
        end;
      end;
  finally
    EdgeFilter.Free;
  end;
  Result:=Rings.Count;
  {$IFDEF CHECK_GRAPHS} { ����������� }
  if not CompleteRingSystem(Rings) then
    Error(SAlgorithmFailure);
  {$ENDIF}
end;

{$IFDEF NOWARN}{$WARNINGS OFF}{$ENDIF}
function TGraph.EdgePathToVertexPath(FromVertex: TVertex;
  EdgePath, VertexPath: TClassList): Bool;
var
  I: Integer;
  V: TVertex;
  E: TEdge;
begin
  VertexPath.Clear;
  if EdgePath.Count > 0 then begin
    for I:=0 to EdgePath.Count - 1 do begin
      E:=EdgePath[I];
      if E.V1 = FromVertex then
        V:=E.V2
      else
        if E.V2 = FromVertex then
          V:=E.V1
        else begin
          VertexPath.Clear;
          Result:=False;
          Exit;
        end;
      VertexPath.Add(FromVertex);
      FromVertex:=V;
    end;
    VertexPath.Add(FromVertex);
    VertexPath.Pack;
  end;
  Result:=True;
end;
{$IFDEF NOWARN}{$WARNINGS ON}{$ENDIF}

procedure TGraph.DetectConnected;
{ ����������� ��������� ����� � ������� ��������� ��������� }
var
  I, J, NumFired: Integer;
  NoProgress: Bool;
  V1, V2: TVertex;
  OldFront, NewFront, T: TClassList;
begin
  if FVertices.Count > 1 then begin
    if FEdges.Count >= FVertices.Count - 1 then begin
    { ����������� ����������� ������� ���������: |E|>=|V2|-1 }
      SetTempForVertices(-1);
      OldFront:=TClassList.Create;
      NewFront:=TClassList.Create;
      try
        NumFired:=1;
        TVertex(FVertices[0]).FTemp.AsInt32:=0;
        OldFront.Add(FVertices[0]);
        repeat
          NoProgress:=True;
          for I:=0 to OldFront.Count - 1 do begin
            V1:=OldFront[I];
            for J:=0 to V1.NeighbEdges.Count - 1 do begin
              V2:=V1.Neighbour[J];
              if V2.FTemp.AsInt32 = -1 then begin
                Inc(NumFired);
                V2.FTemp.AsInt32:=0;
                NewFront.Add(V2);
                NoProgress:=False;
              end;
            end;
          end;
          if NoProgress then begin
            FConnected:=False;
            Break;
          end;
          if NumFired = FVertices.Count then begin
            FConnected:=True;
            Break;
          end;
          T:=OldFront;
          OldFront:=NewFront;
          NewFront:=T;
          NewFront.Clear;
        until False;
      finally
        OldFront.Free;
        NewFront.Free;
      end;
    end
    else
      FConnected:=False;
  end
  else
    FConnected:=FVertices.Count = 1;
  Include(FStates, gsValidConnected);
end;

procedure TGraph.DetectSeparates;
{ ����������� ��������� ��������� ����� � ������� ��������� ��������� }
var
  I, J, K, SeparateOffset: Integer;
  NoProgress: Bool;
  V1, V2: TVertex;
  OldFront, NewFront, T: TClassList;
  OldStates: TGraphObjectStates;
begin
  OldStates:=States;
  States:=States + [gsValidSeparates]; { �������� ������ - �������� �������� }
  try
    if (gsValidConnected in FStates) and FConnected then
      FSeparateCount:=1
    else begin
      FSeparateCount:=0;
      SetTempForVertices(-1);
      OldFront:=TClassList.Create;
      NewFront:=TClassList.Create;
      try
        for I:=0 to FVertices.Count - 1 do begin
          V1:=FVertices[I];
          if V1.FTemp.AsInt32 = -1 then begin
            V1.FTemp.AsInt32:=FSeparateCount;
            OldFront.Clear;
            OldFront.Add(V1);
            repeat
              NoProgress:=True;
              for J:=0 to OldFront.Count - 1 do begin
                V1:=OldFront[J];
                for K:=0 to V1.NeighbEdges.Count - 1 do begin
                  V2:=V1.Neighbour[K];
                  if V2.FTemp.AsInt32 = -1 then begin
                    V2.FTemp.AsInt32:=FSeparateCount;
                    NewFront.Add(V2);
                    NoProgress:=False;
                  end;
                end;
              end;
              if NoProgress then
                Break;
              T:=OldFront;
              OldFront:=NewFront;
              NewFront:=T;
              NewFront.Clear;
            until False;
            Inc(FSeparateCount);
          end;
        end;
        FConnected:=FSeparateCount = 1;
        Include(FStates, gsValidConnected);
        SeparateOffset:=FVertexAttrMap.Offset(GAttrSeparateIndex);
        for I:=0 to FVertices.Count - 1 do begin
          V1:=FVertices[I];
          V1.AsInt32ByOfs[SeparateOffset]:=V1.FTemp.AsInt32;
        end;
      finally
        OldFront.Free;
        NewFront.Free;
      end;
    end;
  except
    States:=OldStates;
    raise;
  end;
end;

function TGraph.DetectRingsAcceptEdge(Edge: TEdge; FromVertex: TVertex): Bool;
begin
  Result:=Edge <> FTemp.AsPointer;
end;

function TGraph.DetectRingsAcceptArc(Edge: TEdge; FromVertex: TVertex): Bool;
begin
  Result:=(Edge <> FTemp.AsPointer) and (Edge.V1 = FromVertex);
end;

procedure TGraph.DetectRingEdges;
var
  I, J, RingOffset, PathLength: Integer;
  B: Bool;
  V: TVertex;
  E, SaveOne: TEdge;
begin
  States:=States + [gsValidRingEdges]; { �������� ������ - �������� �������� }
  try
    FRingEdgeCount:=0;
    if FVertices.Count = 0 then
      Exit;
    if not (Directed in Features) then begin
      { �������� ���������� ��������� ����� � ������� ��������� ���������;
        ��������� ������������ ����� Temp �����: 0 => ����������, 1 => ��������� }
      BFSFromVertex(FVertices[0]);
      { ���� �������'�� ����� ������ ���������, �� ����� �������� ���������
        ("������� ����� �� �����") }
      for I:=0 to FEdges.Count - 1 do With TEdge(FEdges[I]) do
        FTemp.AsInt32:=Ord(V1.TimeMark = V2.TimeMark);
      { ���� ��������������� ����� ����� ��� ���� ����������� ����� �������
        ����� ������� �������'�� �����, ��� ��� �������, �� ����� - ���������
        ("������� ����� �� �������") }
      for I:=0 to FVertices.Count - 1 do begin
        V:=FVertices[I];
        SaveOne:=nil;
        for J:=0 to V.NeighbEdges.Count - 1 do begin
          E:=V.NeighbEdges[J];
          if E.OtherVertex(V).TimeMark < V.TimeMark then
            if SaveOne = nil then
              SaveOne:=E
            else begin
              SaveOne.FTemp.AsInt32:=1;
              E.FTemp.AsInt32:=1;
            end;
        end;
      end;
    end
    else
      SetTempForEdges(0);
    { ������������ ��������� ����� }
    RingOffset:=FEdgeAttrMap.Offset(GAttrRingEdge);
    for I:=0 to FEdges.Count - 1 do begin
      E:=FEdges[I];
      if E.Temp.AsInt32 = 1 then
        B:=True
      { ������� ������ �� ������ ����� ������� => �������� ����������� }
      else if (E.V1.NeighbEdges.Count = 1) or (E.V2.NeighbEdges.Count = 1) then
        B:=False
      else begin
        FTemp.AsPointer:=E;
        if Directed in Features then
          PathLength:=FindMinPathCond(E.V2, E.V1, nil, DetectRingsAcceptArc, nil)
        else
          PathLength:=FindMinPathCond(E.V1, E.V2, nil, DetectRingsAcceptEdge, nil);
        B:=PathLength >= 0;
      end;
      E.AsBoolByOfs[RingOffset]:=B;
      if B then
        Inc(FRingEdgeCount);
    end;
  except
    Exclude(FStates, gsValidRingEdges);
    raise;
  end;
end;

procedure TGraph.CheckValidConnected;
begin
  if not (gsValidConnected in FStates) then
    DetectConnected;
end;

procedure TGraph.CheckValidSeparates;
begin
  if not (gsValidSeparates in FStates) then
    DetectSeparates;
end;

procedure TGraph.CheckValidRingEdges;
begin
  if not (gsValidRingEdges in FStates) then
    DetectRingEdges;
end;

function TGraph.Connected: Bool;
begin
  CheckValidConnected;
  Result:=FConnected;
end;

function TGraph.MakeConnected(NewEdges: TClassList): Integer;
var
  I: Integer;
  V1, V2: TVertex;
  E: TEdge;
begin
  if NewEdges <> nil then
    NewEdges.Clear;
  Result:=0;
  if FVertices.Count > 0 then begin
    SetTempForVertices(-1);
    V1:=FVertices[0];
    SetTempFromVertex(V1, 0);
    for I:=1 to FVertices.Count - 1 do begin
      V2:=FVertices[I];
      if V2.FTemp.AsInt32 < 0 then begin
        SetTempFromVertex(V2, 0);
        E:=AddEdge(V1, V2);
        Inc(Result);
        if NewEdges <> nil then
          NewEdges.Add(E);
      end;
    end;
    FConnected:=True;
    Include(FStates, gsValidConnected);
  end;
end;

function TGraph.FindArticulationPoints(FromVertex: TVertex; Points: TClassList): Bool;
var
  Counter: Integer;
  LowPt: TIntegerVector;
  Parents: TClassList;

  function FindFrom(V: TVertex): Bool;
  var
    I: Integer;
    U, Neighbour: TVertex;
  begin
    Result:=False;
    V.FTemp.AsInt32:=Counter;
    LowPt[V.Index]:=Counter;
    Inc(Counter);
    U:=nil;
    for I:=0 to V.NeighbEdges.Count - 1 do begin
      Neighbour:=V.Neighbour[I];
      if Neighbour <> V then begin
        if U = nil then
          U:=Neighbour;
        if Neighbour.FTemp.AsInt32 < 0 then begin
          Parents[Neighbour.Index]:=V;
          if FindFrom(Neighbour) then begin
            Result:=True;
            if Points = nil then
              Exit;
          end;
          if (LowPt[Neighbour.Index] = V.FTemp.AsInt32) and
            ((Neighbour <> U) or (Parents[V.Index] <> nil)) then
          begin
            { V - ���� ���������� (�������� V �������� � ������ ���������) }
            Result:=True;
            if Points = nil then
              Exit;
            Points.Add(V)
          end;
          LowPt[V.Index]:=IntMin(LowPt[V.Index], LowPt[Neighbour.Index]);
        end
        else
          LowPt[V.Index]:=IntMin(LowPt[V.Index], Neighbour.FTemp.AsInt32);
      end;
    end;
  end;

begin
  if Points <> nil then
    Points.Clear;
  SetTempForVertices(-1);
  LowPt:=TIntegerVector.Create(FVertices.Count, -1);
  Parents:=TClassList.Create;
  try
    Parents.Count:=FVertices.Count;
    Counter:=0;
    Result:=FindFrom(FromVertex);
  finally
    LowPt.Free;
    Parents.Free;
  end;
end;

function TGraph.Biconnected(ArticulationPoints: TClassList): Bool;
begin
  if Connected then
    Result:=not FindArticulationPoints(FVertices[0], ArticulationPoints)
  else
    Result:=False;
end;

function TGraph.MakeBiconnected(NewEdges: TClassList): Integer;
var
  Counter: Integer;
  LowPt: TIntegerVector;
  Parents: TClassList;

  procedure MakeFrom(V: TVertex);
  var
    I: Integer;
    U, Neighbour: TVertex;
    E: TEdge;
  begin
    V.FTemp.AsInt32:=Counter;
    LowPt[V.Index]:=Counter;
    Inc(Counter);
    U:=nil;
    for I:=0 to V.NeighbEdges.Count - 1 do begin
      Neighbour:=V.Neighbour[I];
      if Neighbour <> V then begin
        if U = nil then
          U:=Neighbour;
        if Neighbour.FTemp.AsInt32 < 0 then begin
          Parents[Neighbour.Index]:=V;
          MakeFrom(Neighbour);
          if LowPt[Neighbour.Index] = V.FTemp.AsInt32 then
            if Neighbour = U then
              if Parents[V.Index] <> nil then begin
               { V - ���� ���������� }
                E:=AddEdge(Parents[V.Index], Neighbour);
                Inc(Result);
                if NewEdges <> nil then
                  NewEdges.Add(E);
              end
              else
            else begin
              { V - ���� ���������� }
              E:=AddEdge(U, Neighbour);
              Inc(Result);
              if NewEdges <> nil then
                NewEdges.Add(E);
            end;
          LowPt[V.Index]:=IntMin(LowPt[V.Index], LowPt[Neighbour.Index]);
        end
        else
          LowPt[V.Index]:=IntMin(LowPt[V.Index], Neighbour.FTemp.AsInt32);
      end;
    end;
  end;

var
  N: Integer;
begin
  N:=FVertices.Count;
  if N > 0 then begin
    if NewEdges <> nil then
      NewEdges.Clear;
    Result:=MakeConnected(NewEdges);
    SetTempForVertices(-1);
    LowPt:=TIntegerVector.Create(N, -1);
    Parents:=TClassList.Create;
    try
      Parents.Count:=N;
      Counter:=0;
      MakeFrom(FVertices[0]);
    finally
      LowPt.Free;
      Parents.Free;
    end;
    FConnected:=True;
    Include(FStates, gsValidConnected);
  end
  else
    Result:=0;
end;

function TGraph.Bipartite(A: TBoolVector): Bool;

  function BipartiteDFS(FromVertex: TVertex): Bool;
  var
    I: Integer;
    V, Neighbour: TVertex;
    Q: TPointerQueue;
  begin
    FromVertex.FTemp.AsInt32:=0;
    Q:=TPointerQueue.Create;
    try
      Q.AddAfter(FromVertex);
      repeat
        V:=Q.Head;
        for I:=0 to V.NeighbEdges.Count - 1 do begin
          Neighbour:=V.Neighbour[I];
          if Neighbour.FTemp.AsInt32 = -1 then begin
            Q.AddAfter(Neighbour);
            Neighbour.FTemp.AsInt32:=1 - V.FTemp.AsInt32;
          end
          else
            if Neighbour.FTemp.AsInt32 = V.FTemp.AsInt32 then begin
              Result:=False;
              Exit;
            end;
        end;
        Q.DeleteHead;
      until Q.IsEmpty;
      Result:=True;
    finally
      Q.Free;
    end;
  end;

var
  I: Integer;
  V: TVertex;
begin
  SetTempForVertices(-1);
  for I:=0 to FVertices.Count - 1 do begin
    V:=FVertices[I];
    if (V.FTemp.AsInt32 = -1) and not BipartiteDFS(V) then begin
      Result:=False;
      Exit;
    end;
  end;
  if A <> nil then begin
    A.Count:=FVertices.Count;
    for I:=0 to FVertices.Count - 1 do
      A[I]:=TVertex(FVertices[I]).FTemp.AsInt32 <> 0;
  end;
  Result:=True;
end;

function TGraph.IsTree: Bool;
begin
  Result:=(FEdges.Count = FVertices.Count - 1) and Connected;
end;

function TGraph.IsRegular: Bool;
var
  I, OldDegree: Integer;
begin
  if FVertices.Count > 0 then begin
    OldDegree:=TVertex(FVertices[0]).NeighbEdges.Count;
    for I:=1 to FVertices.Count - 1 do
      if TVertex(FVertices[I]).NeighbEdges.Count <> OldDegree then begin
        Result:=False;
        Exit;
      end;
  end;
  Result:=True;
end;

function TGraph.HasParallelEdges: Bool;
var
  I, J: Integer;
  E1, E2: TEdge;
  NeighbEdges: TClassList;
begin
  for I:=0 to FEdges.Count - 1 do begin
    E1:=FEdges[I];
    NeighbEdges:=E1.V1.NeighbEdges;
    if E1.V2.NeighbEdges.Count < NeighbEdges.Count then
      NeighbEdges:=E1.V2.NeighbEdges;
    for J:=0 to NeighbEdges.Count - 1 do begin
      E2:=NeighbEdges[J];
      if (E2 <> E1) and E2.ParallelToEdge(E1) then begin
        Result:=True;
        Exit;
      end;
    end;
  end;
  Result:=False;
end;

{$IFDEF V_ALLOW_DEPRECATE}
function TGraph.HasDuplicateEdges: Bool;
begin
  Result:=HasParallelEdges;
end;
{$ENDIF}

function TGraph.HasLoops: Bool;
var
  I: Integer;
begin
  for I:=0 to FEdges.Count - 1 do
    if TEdge(FEdges[I]).IsLoop then begin
      Result:=True;
      Exit;
    end;
  Result:=False;
end;

function TGraph.RemoveParallelEdges: Bool;
var
  I, J, K, N: Integer;
  M: TIntegerMatrix;
begin
  Result:=False;
  M:=CreateExtendedConnectionMatrix;
  try
    N:=FVertices.Count - 1;
    if Directed in Features then
      for I:=0 to N do
        for J:=0 to N do
          for K:=2 to M[I, J] do begin
            Result:=True;
            GetArcI(I, J).Free;
          end
    else
      for I:=0 to N do
        for J:=I to N do
          for K:=2 to M[I, J] do begin
            Result:=True;
            GetEdgeI(I, J).Free;
          end;
  finally
    M.Free;
  end;
end;

{$IFDEF V_ALLOW_DEPRECATE}
function TGraph.RemoveDuplicateEdges: Bool;
begin
  Result:=RemoveParallelEdges;
end;
{$ENDIF}

function TGraph.RemoveLoops: Bool;
var
  I: Integer;
  E: TEdge;
begin
  Result:=False;
  for I:=FEdges.Count - 1 downto 0 do begin
    E:=FEdges[I];
    if E.IsLoop then begin
      E.Free;
      Result:=True;
    end;
  end;
end;

function TGraph.HideLoops(Loops: TClassList): Integer;
var
  I: Integer;
  E: TEdge;
begin
  Loops.Clear;
  for I:=FEdges.Count - 1 downto 0 do begin
    E:=FEdges[I];
    if E.IsLoop then begin
      E.Hide;
      Loops.Add(E);
    end;
  end;
  Loops.Pack;
  Result:=Loops.Count;
end;

procedure TGraph.RestoreLoops(Loops: TClassList);
var
  I: Integer;
begin
  for I:=Loops.Count - 1 downto 0 do
    TEdge(Loops[I]).Restore;
end;

function TGraph.ParallelEdgeCount: Integer;
var
  I, J: Integer;
  E1, E2: TEdge;
begin
  Result:=0;
  for I:=0 to FEdges.Count - 1 do begin
    E1:=FEdges[I];
    for J:=0 to E1.V1.NeighbEdges.Count - 1 do begin
      E2:=E1.V1.NeighbEdges[J];
      if (E2 <> E1) and E2.ParallelToEdge(E1) then begin
        Inc(Result);
        Break;
      end;
    end;
  end;
end;

{$IFDEF V_ALLOW_DEPRECATE}
function TGraph.DuplicateEdgeCount: Integer;
begin
  Result:=ParallelEdgeCount;
end;
{$ENDIF}

function TGraph.LoopCount: Integer;
var
  I: Integer;
begin
  Result:=0;
  for I:=0 to FEdges.Count - 1 do
    if TEdge(FEdges[I]).IsLoop then
      Inc(Result);
end;

function TGraph.SeparateCount: Integer;
begin
  CheckValidSeparates;
  Result:=FSeparateCount;
end;

function TGraph.RingEdgeCount: Integer;
begin
  CheckValidRingEdges;
  Result:=FRingEdgeCount;
end;

function TGraph.CyclomaticNumber: Integer;
begin
  Result:=FEdges.Count - FVertices.Count + SeparateCount;
end;

function TGraph.GetEdge(Vertex1, Vertex2: TVertex): TEdge;
var
  I: Integer;
begin
  Result:=nil;
  if Vertex1 <> nil then
    for I:=0 to Vertex1.NeighbEdges.Count - 1 do
      if Vertex1.Neighbour[I] = Vertex2 then begin
        Result:=Vertex1.NeighbEdges[I];
        Exit;
      end;
end;

function TGraph.GetEdgeI(I1, I2: Integer): TEdge;
var
  N: Integer;
begin
  N:=FVertices.Count;
  if (I1 >= 0) and (I1 < N) and (I2 >= 0) and (I2 < N) then
    Result:=GetEdge(FVertices[I1], FVertices[I2])
  else
    Result:=nil;
end;

procedure TGraph.GetEdges(EdgeList: TClassList; Vertex1, Vertex2: TVertex);
var
  I: Integer;
begin
  EdgeList.Clear;
  if Vertex1 <> nil then begin
    for I:=0 to Vertex1.NeighbEdges.Count - 1 do
      if Vertex1.Neighbour[I] = Vertex2 then
        EdgeList.Add(Vertex1.NeighbEdges[I]);
    EdgeList.Pack;
  end;
end;

procedure TGraph.GetEdgesI(EdgeList: TClassList; I1, I2: Integer);
var
  N: Integer;
  V1, V2: TVertex;
begin
  N:=FVertices.Count;
  V1:=nil;
  if (I1 >= 0) and (I1 < N) then
    V1:=FVertices[I1];
  V2:=nil;
  if (I2 >= 0) and (I2 < N) then
    V2:=FVertices[I2];
  GetEdges(EdgeList, V1, V2);
end;

procedure TGraph.SetFeatures(Value: TGraphFeatures);
begin
  if Value <> FFeatures then begin
    if (Directed in Value) xor (Directed in FFeatures) then
      Exclude(FStates, gsValidRingEdges);
    if Tree in Value then begin
      Map.SafeCreateAttr(GAttrRoot, AttrPointer);
      SafeCreateVertexAttr(GAttrHasParent, AttrBool);
    end
    else begin
      Map.SafeDropAttr(GAttrRoot);
      SafeDropVertexAttr(GAttrHasParent);
    end;
    if Network in Value then begin
      Include(Value, Directed); { ���� - ������ ������ }
      Map.SafeCreateAttr(GAttrNetworkSource, AttrPointer);
      Map.SafeCreateAttr(GAttrNetworkSink, AttrPointer);
      SafeCreateEdgeAttr(GAttrMaxFlow, AttrFloat);
      SafeCreateEdgeAttr(GAttrFlow, AttrFloat);
    end
    else begin
      Map.SafeDropAttr(GAttrNetworkSource);
      Map.SafeDropAttr(GAttrNetworkSink);
      SafeDropEdgeAttr(GAttrMaxFlow);
      SafeDropEdgeAttr(GAttrFlow);
    end;
    if Weighted in Value then
      SafeCreateEdgeAttr(GAttrWeight, AttrFloat)
    else
      SafeDropEdgeAttr(GAttrWeight);
    if Geom3D in Value then
      Include(Value, Geom2D);
    if Geom2D in Value then begin
      SafeCreateVertexAttr(GAttrX, AttrFloat);
      SafeCreateVertexAttr(GAttrY, AttrFloat);
    end
    else begin
      SafeDropVertexAttr(GAttrX);
      SafeDropVertexAttr(GAttrY);
    end;
    if Geom3D in Value then
      SafeCreateVertexAttr(GAttrZ, AttrFloat)
    else
      SafeDropVertexAttr(GAttrZ);
    FFeatures:=Value;
  end;
end;

procedure TGraph.SetTempToSubtreeSize(FromVertex: TVertex);
var
  I: Integer;
  E: TEdge;

  function CountSubTrees(V: TVertex): Integer;
  var
    I: Integer;
    E: TEdge;
  begin
    Result:=0;
    for I:=0 to V.NeighbEdges.Count - 1 do begin
      E:=V.NeighbEdges[I];
      if E.FTemp.AsInt32 = -2 then begin
        E.FTemp.AsInt32:=-1;
        Inc(Result, CountSubTrees(E.OtherVertex(V)) + 1);
      end;
    end;
    V.FTemp.AsInt32:=Result;
  end;

begin
  BFSFromVertex(FromVertex);
  for I:=0 to FEdges.Count - 1 do begin
    E:=FEdges[I];
    { ��������� ����� � "��������������" ����� }
    if E.V1.FTemp.AsInt32 <> E.V2.FTemp.AsInt32 then
      E.FTemp.AsInt32:=-2
    else
      E.FTemp.AsInt32:=0;
  end;
  CountSubTrees(FromVertex);
end;

procedure TGraph.TreeTraversal(FromVertex: TVertex; VertexPath: TClassList);

  procedure DoTraversal(V: TVertex);
  var
    I: Integer;
    VTemp: Int32;
    Neighbour: TVertex;
  begin
    VertexPath.Add(V);
    VTemp:=V.FTemp.AsInt32;
    for I:=0 to V.NeighbEdges.Count - 1 do begin
      Neighbour:=V.Neighbour[I];
      if Neighbour.FTemp.AsInt32 > VTemp then
        DoTraversal(Neighbour);
    end;
  end;

begin
  VertexPath.Clear;
  BFSFromVertex(FromVertex);
  DoTraversal(FromVertex);
  VertexPath.Pack;
end;

type
  { ������������ ��� ���������� ����������� }
  TArrangeHelper = class
    Limit: Int32;
    CurrentVertex: TVertex;
    FCompareVertices, FCompareEdges: TCompareEvent;
    constructor Create(ACompareVertices, ACompareEdges: TCompareEvent);
    function CompareEdges(Edge1, Edge2: Pointer): Integer;
  end;

constructor TArrangeHelper.Create(ACompareVertices, ACompareEdges: TCompareEvent);
begin
  inherited Create;
  FCompareVertices:=ACompareVertices;
  FCompareEdges:=ACompareEdges;
end;

function TArrangeHelper.CompareEdges(Edge1, Edge2: Pointer): Integer;
var
  B: Bool;
  V1, V2: TVertex;

  function CompareSubtrees(From1, From2: TVertex): Integer;
  { ���������� ���������� ����� � ������� From1 � From2 }
  var
    I: Integer;
    DownEdges1, DownEdges2: TClassList;

    procedure GetDownEdges(From: TVertex; DownEdges: TClassList);
    { ���������� �����, ������� � �������� �������� }
    var
      I: Integer;
      VTemp: Int32;
      E: TEdge;
    begin
      DownEdges.Clear;
      VTemp:=From.FTemp.AsInt32;
      for I:=0 to From.NeighbEdges.Count - 1 do begin
        E:=From.NeighbEdges[I];
        if (E.FTemp.AsInt32 = -1) and (E.OtherVertex(From).FTemp.AsInt32 < VTemp) then
          DownEdges.Add(E);
      end;
    end;

  begin
    { �������� ���������� ������ � ����������� }
    Result:=From1.FTemp.AsInt32 - From2.FTemp.AsInt32;
    if Result = 0 then begin
      { �������� ������� ������ }
      Result:=From1.NeighbEdges.Count - From2.NeighbEdges.Count;
      if Result = 0 then begin
        { �������� �������� ������ }
        Result:=FCompareVertices(From1, From2);
        if Result = 0 then begin
          { ���������� �����, ������� � �������� �������� }
          DownEdges1:=TClassList.Create;
          DownEdges2:=TClassList.Create;
          try
            GetDownEdges(From1, DownEdges1);
            GetDownEdges(From2, DownEdges2);
            Result:=DownEdges1.Count - DownEdges2.Count;
            if Result = 0 then begin
              { �������� �������� �����, ������� � �������� �������� }
              for I:=0 to DownEdges1.Count - 1 do begin
                Result:=FCompareEdges(DownEdges1[I], DownEdges2[I]);
                if Result <> 0 then
                  Exit;
              end;
              { �������� ���������� }
              for I:=0 to DownEdges1.Count - 1 do begin
                Result:=CompareSubtrees(TEdge(DownEdges1[I]).OtherVertex(From1),
                  TEdge(DownEdges2[I]).OtherVertex(From2));
                if Result <> 0 then
                  Exit;
              end;
            end;
          finally
            DownEdges1.Free;
            DownEdges2.Free;
          end;
        end; {if}
      end; {if}
    end; {if}
  end;

begin
  if Edge1 <> Edge2 then begin
    V1:=TEdge(Edge1).OtherVertex(CurrentVertex);
    V2:=TEdge(Edge2).OtherVertex(CurrentVertex);
    B:=V1.FTemp.AsInt32 < Limit;
    if B and (V2.FTemp.AsInt32 < Limit) then
      Result:=CompareSubtrees(V1, V2)
    else { ���� �� ����� - ������ "�����" }
      if B then
        Result:=-1
      else
        Result:=1;
  end
  else
    Result:=0;
end;

procedure TGraph.ArrangeTree(FromVertex: TVertex; CompareVertices,
  CompareEdges: TCompareEvent);
var
  ArrangeHelper: TArrangeHelper;

  procedure DoArrange(V: TVertex);
  var
    I: Integer;
    E: TEdge;
  begin
    for I:=0 to V.NeighbEdges.Count - 1 do begin
      E:=V.NeighbEdges[I];
      if E.FTemp.AsInt32 = -1 then begin
        E.FTemp.AsInt32:=-2;
        DoArrange(E.OtherVertex(V));
      end;
    end;
    ArrangeHelper.Limit:=V.FTemp.AsInt32;
    ArrangeHelper.CurrentVertex:=V;
    V.NeighbEdges.ConservativeSortByObject(ArrangeHelper.CompareEdges);
  end;

begin
  if not IsTree then
    Error(SMethodNotApplicable);
  SetTempToSubtreeSize(FromVertex);
  ArrangeHelper:=TArrangeHelper.Create(CompareVertices, CompareEdges);
  try
    DoArrange(FromVertex);
  finally
    ArrangeHelper.Free;
  end;
end;

procedure TGraph.SortTree(FromVertex: TVertex; CompareVertices: TCompareEvent);

  procedure DoSort(V: TVertex);
  var
    I: Integer;
  begin
    for I:=0 to V.ChildCount - 1 do
      DoSort(V.Childs[I]);
    V.SortChilds(CompareVertices);
  end;

begin
  DoSort(FromVertex);
end;

function TGraph.CreateConnectionMatrix: TBoolMatrix;
var
  I: Integer;
  E: TEdge;
begin
  I:=FVertices.Count;
  if Directed in Features then
    Result:=TBoolMatrix.Create(I, I, False)
  else
    Result:=TSimBoolMatrix.Create(I, False);
  try
    Result.SetDiagonal(True);
    for I:=0 to FEdges.Count - 1 do begin
      E:=FEdges[I];
      Result[E.V1.Index, E.V2.Index]:=True;
    end;
  except
    Result.Free;
    raise;
  end;
end;

function TGraph.CreateExtendedConnectionMatrix: TIntegerMatrix;
var
  I: Integer;
  E: TEdge;
begin
  I:=FVertices.Count;
  if Directed in Features then
    Result:=TIntegerMatrix.Create(I, I, 0)
  else
    Result:=TSimIntegerMatrix.Create(I, 0);
  try
    for I:=0 to FEdges.Count - 1 do begin
      E:=FEdges[I];
      Result.IncItem(E.V1.Index, E.V2.Index, 1);
    end;
  except
    Result.Free;
    raise;
  end;
end;

function TGraph.CreateReachabilityMatrix: TBoolMatrix;
var
  I, J, K, N: Integer;
  Changed: Bool;
begin
  N:=FVertices.Count;
  if not (Directed in Features) then begin
    Result:=TSimBoolMatrix.Create(N, False);
    if SeparateCount = 1 then
      Result.Vector.FillValue(True)
    else begin
      for I:=0 to N - 1 do begin
        K:=TVertex(FVertices[I]).SeparateIndex;
        for J:=I to N - 1 do
          if TVertex(FVertices[J]).SeparateIndex = K then
            Result[I, J]:=True;
      end;
    end;
  end
  else begin
    Result:=CreateConnectionMatrix;
    try
      repeat
        Changed:=False;
        for I:=0 to N - 1 do
          for J:=0 to N - 1 do
            if (I <> J) and Result[I, J] then begin
              for K:=0 to N - 1 do
                if Result[J, K] and not Result[I, K] then begin
                  Result[I, K]:=True;
                  Changed:=True;
                end;
              for K:=0 to N - 1 do
                if Result[K, I] and not Result[K, J] then begin
                  Result[K, J]:=True;
                  Changed:=True;
                end;
            end;
       until not Changed;
    except
      Result.Free;
      raise;
    end;
  end;
end;

function TGraph.CreateIncidenceMatrix: TBoolMatrix;
var
  I: Integer;
begin
  Result:=TBoolMatrix.Create(FVertices.Count, FEdges.Count, False);
  try
    for I:=0 to FEdges.Count - 1 do With TEdge(FEdges[I]) do begin
      Result[V1.Index, I]:=True;
      Result[V2.Index, I]:=True;
    end;
  except
    Result.Free;
    raise;
  end;
end;

function TGraph.CreateDistanceMatrix: TIntegerMatrix;
var
  I, J, N: Integer;
begin
  N:=FVertices.Count;
  Result:=nil;
  try
    if Directed in Features then begin
      Result:=TIntegerMatrix.Create(N, N, 0);
      for I:=0 to N - 1 do begin
        BFSFromVertexDirected(FVertices[I]);
        for J:=0 to N - 1 do
          Result[I, J]:=TVertex(FVertices[J]).FTemp.AsInt32;
      end;
    end
    else begin
      Result:=TSimIntegerMatrix.Create(N, 0);
      for I:=0 to N - 1 do begin
        BFSFromVertex(FVertices[I]);
        for J:=I + 1 to N - 1 do
          Result[I, J]:=TVertex(FVertices[J]).FTemp.AsInt32;
      end;
    end;
  except
    Result.Free;
    raise;
  end;
end;

function TGraph.CreateDegreesVector: TIntegerVector;
var
  I, N: Integer;
begin
  N:=FVertices.Count;
  Result:=TIntegerVector.Create(N, 0);
  try
    for I:=0 to N - 1 do
      Result[I]:=TVertex(FVertices[I]).NeighbEdges.Count;
  except
    Result.Free;
    raise;
  end;
end;

function TGraph.CreateInt64DegreesVector: TInt64Vector;
var
  I, N: Integer;
begin
  N:=FVertices.Count;
  Result:=TInt64Vector.Create(N, 0);
  try
    for I:=0 to N - 1 do
      Result[I]:=TVertex(FVertices[I]).NeighbEdges.Count;
  except
    Result.Free;
    raise;
  end;
end;

function TGraph.UpdateSpectrum(Spectrum, SortedSpectrum, TempVector: TInt64Vector): Integer;
var
  I, J, N: Integer;
  OldValue: Int64;
  V: TVertex;
begin
  Result:=0;
  N:=FVertices.Count;
  if N > 0 then begin
    TempVector.Assign(Spectrum);
    for I:=0 to N - 1 do begin
      V:=FVertices[I];
      for J:=0 to V.NeighbEdges.Count - 1 do
        Spectrum.IncItem(I, TempVector[TEdge(V.NeighbEdges[J]).OtherVertex(V).Index]);
    end;
    if SortedSpectrum = nil then
      SortedSpectrum:=TempVector;
    SortedSpectrum.Assign(Spectrum);
    SortedSpectrum.Sort;
    OldValue:=SortedSpectrum[0];
    Inc(Result);
    for I:=1 to N - 1 do
      if SortedSpectrum[I] <> OldValue then begin
        Inc(Result);
        OldValue:=SortedSpectrum[I];
      end;
  end;
end;

{$IFDEF NOWARN}{$WARNINGS OFF}{$ENDIF}
function TGraph.EqualToGraph(G: TGraph; IsomorphousMap: TGenericIntegerVector;
  CompareVertices, CompareEdges: TCompareFunc): Bool;

  function CompareNeighbIndexes(NeighbIndexes1, NeighbIndexes2: TIntegerVector;
    NeighbEdges1, NeighbEdges2: TClassList): Bool;
  begin
    if Assigned(CompareEdges) then begin
      NeighbIndexes1.SortWith(NeighbEdges1);
      NeighbIndexes2.SortWith(NeighbEdges2);
    end
    else begin
      NeighbIndexes1.Sort;
      NeighbIndexes2.Sort;
    end;
    Result:=NeighbIndexes1.EqualTo(NeighbIndexes2);
  end;

  function CompareNeighbEdges(NeighbIndexes: TIntegerVector;
    NeighbEdges1, NeighbEdges2: TClassList): Bool;
  var
    RangeBegin, RangeEnd: Integer;

    function CompareRange: Bool;
    var
      K, L: Integer;
      Found: Bool;
      E: TEdge;
    begin
      Result:=False;
      if RangeEnd > RangeBegin then
        for K:=RangeBegin to RangeEnd do begin
          Found:=False;
          E:=NeighbEdges1[K];
          for L:=RangeBegin to RangeEnd do
            if (NeighbEdges2[L] <> nil) and
              (CompareEdges(E, NeighbEdges2[L]) = 0) then
            begin
              Found:=True;
              NeighbEdges2[L]:=nil;
              Break;
            end;
          if not Found then
            Exit;
        end
      else
        if CompareEdges(NeighbEdges1[RangeBegin], NeighbEdges2[RangeBegin]) <> 0 then
          Exit;
      Result:=True;
    end;

  var
    I, N, LastNeighbour: Integer;
  begin
    N:=NeighbIndexes.Count;
    if N > 0 then begin
      Result:=False;
      LastNeighbour:=NeighbIndexes[0];
      RangeBegin:=0;
      RangeEnd:=0;
      for I:=1 to N - 1 do begin
        if NeighbIndexes[I] <> LastNeighbour then begin
          if not CompareRange then
            Exit;
          RangeBegin:=I;
        end;
        Inc(RangeEnd);
      end;
      if not CompareRange then
        Exit;
    end;
    Result:=True;
  end;

var
  I, J, N: Integer;
  IsDirected: Bool;
  V1, V2: TVertex;
  E: TEdge;
  InNeighbIndexes1, InNeighbIndexes2, OutNeighbIndexes1, OutNeighbIndexes2: TIntegerVector;
  InNeighbEdges1, InNeighbEdges2, OutNeighbEdges1, OutNeighbEdges2: TClassList;
begin
  Result:=False;
  if (FVertices.Count = G.FVertices.Count) and (FEdges.Count = G.FEdges.Count) and
    ((Directed in Features) = (Directed in G.Features)) then
  begin
    for I:=0 to FVertices.Count - 1 do
      TVertex(FVertices[I]).FTemp.AsInt32:=IsomorphousMap[I];
    InNeighbIndexes1:=TIntegerVector.Create(0, 0);
    InNeighbIndexes2:=TIntegerVector.Create(0, 0);
    IsDirected:=Directed in Features;
    if IsDirected then begin
      OutNeighbIndexes1:=TIntegerVector.Create(0, 0);
      OutNeighbIndexes2:=TIntegerVector.Create(0, 0);
    end;
    if Assigned(CompareEdges) or IsDirected then begin
      InNeighbEdges1:=TClassList.Create;
      InNeighbEdges2:=TClassList.Create;
      if IsDirected then begin
        OutNeighbEdges1:=TClassList.Create;
        OutNeighbEdges2:=TClassList.Create;
      end;
    end;
    try
      for I:=0 to FVertices.Count - 1 do begin
        V1:=FVertices[I];
        V2:=G.FVertices[IsomorphousMap[I]];
        N:=V1.NeighbEdges.Count;
        { ��������� ���������� �������� ������, � ����� �� ��������� }
        if (N <> V2.NeighbEdges.Count) or
          Assigned(CompareVertices) and (CompareVertices(V1, V2) <> 0) then
            Exit;
        if N > 0 then begin
          { ��������� ���������� "���������" }
          if IsDirected then begin
            InNeighbIndexes1.Clear;
            InNeighbEdges1.Clear;
            OutNeighbIndexes1.Clear;
            OutNeighbEdges1.Clear;
            for J:=0 to V1.NeighbEdges.Count - 1 do begin
              E:=V1.NeighbEdges[J];
              if E.V1 = V1 then begin
                OutNeighbEdges1.Add(E);
                OutNeighbIndexes1.Add(E.V2.FTemp.AsInt32);
              end
              else begin
                InNeighbEdges1.Add(E);
                InNeighbIndexes1.Add(E.V1.FTemp.AsInt32);
              end;
            end;
            InNeighbIndexes2.Clear;
            InNeighbEdges2.Clear;
            OutNeighbIndexes2.Clear;
            OutNeighbEdges2.Clear;
            for J:=0 to V2.NeighbEdges.Count - 1 do begin
              E:=V2.NeighbEdges[J];
              if E.V1 = V2 then begin
                OutNeighbEdges2.Add(E);
                OutNeighbIndexes2.Add(E.V2.Index);
              end
              else begin
                InNeighbEdges2.Add(E);
                InNeighbIndexes2.Add(E.V1.Index);
              end;
            end;
            if not CompareNeighbIndexes(OutNeighbIndexes1, OutNeighbIndexes2,
              OutNeighbEdges1, OutNeighbEdges2)
            then
              Exit;
          end
          else begin
            InNeighbIndexes1.Count:=N;
            InNeighbIndexes2.Count:=N;
            for J:=0 to N - 1 do begin
              InNeighbIndexes1[J]:=V1.Neighbour[J].FTemp.AsInt32;
              InNeighbIndexes2[J]:=V2.Neighbour[J].Index;
            end;
            if Assigned(CompareEdges) then begin
              InNeighbEdges1.Assign(V1.NeighbEdges);
              InNeighbEdges2.Assign(V2.NeighbEdges);
            end;
          end;
          if not CompareNeighbIndexes(InNeighbIndexes1, InNeighbIndexes2,
            InNeighbEdges1, InNeighbEdges2)
          then
            Exit;
          { ��������� ���������� ��������� �����; ����� � ������� ����� �������
            ����������� ��������� }
          if Assigned(CompareEdges) then begin
            if not CompareNeighbEdges(InNeighbIndexes1, InNeighbEdges1,
              InNeighbEdges2)
            then
              Exit;
            if IsDirected and not CompareNeighbEdges(OutNeighbIndexes1,
              OutNeighbEdges1, OutNeighbEdges2)
            then
              Exit;
          end;
        end;
      end;
    finally
      InNeighbIndexes1.Free;
      InNeighbIndexes2.Free;
      if IsDirected then begin
        OutNeighbIndexes1.Free;
        OutNeighbIndexes2.Free;
      end;
      if Assigned(CompareEdges) or IsDirected then begin
        InNeighbEdges1.Free;
        InNeighbEdges2.Free;
        if IsDirected then begin
          OutNeighbEdges1.Free;
          OutNeighbEdges2.Free;
        end;
      end;
    end;
    Result:=True;
  end;
end;
{$IFDEF NOWARN}{$WARNINGS ON}{$ENDIF}

{$IFDEF NOWARN}{$WARNINGS OFF}{$ENDIF}
procedure TGraph.FindMaxIndependentVertexSets(SelectCode: TSelectCode;
  SelectParam: Integer; VertexSets: TMultiList);
{ ���������� �������� ���������������� �������� ����� � �������, ��������� �:
  "�.�����������. ������ ������. ��������������� ������. �., ���, 1978 �." }
Label
  Label2, Label3, Label5;
var
  I, J, ExtremumSize: Integer;
  GoodVertex, B1, B2{$IFDEF CHECK_GRAPHS}, B{$ENDIF}: Bool;
  V: TVertex;
  CurrentSet{S}, ExtremumSet, ActiveList, BackList: TClassList;
  SelectedVertices{Xik}: TPointerStack;
  ActiveLists{Q+}, BackLists{Q-}, ExtremumSets: TMultiList;

  procedure ExcludeNeighbours(AMultiList: TMultiList);
  var
    I: Integer;
    AList: TClassList;
  begin
    AList:=AMultiList.Last;
    AMultiList.AddAssign(AList);
    if AList.Count > 0 then
      for I:=0 to V.NeighbEdges.Count - 1 do
        AMultiList.Last.Remove(V.Neighbour[I]);
  end;

begin
  VertexSets.Clear;
  if FVertices.Count > 0 then begin
    CurrentSet:=TClassList.Create;
    SelectedVertices:=TPointerStack.Create;
    ActiveLists:=TMultiList.Create(TClassList);
    BackLists:=TMultiList.Create(TClassList);
    ExtremumSets:=nil;
    if SelectCode in [SelectAnyMin, SelectAnyMax] then begin
      ExtremumSet:=TClassList.Create;
      if SelectCode = SelectAnyMin then
        ExtremumSize:=MaxInt
      else
        ExtremumSize:=0;
    end
    else
      if SelectCode in [SelectAllMin, SelectAllMax] then begin
        ExtremumSets:=TMultiList.Create(TClassList);
        if SelectCode = SelectAllMin then
          ExtremumSize:=MaxInt
        else
          ExtremumSize:=0;
      end;
    try
      ActiveLists.Count:=1;
      ActiveLists[0].Assign(FVertices); { Q+(0) = V }
      BackLists.Count:=1;
      { ������� ������� V �� Q+ �����, ��� ��� ���������� �� � S ����������
        �������� ����������� }
    Label2:
      ActiveList:=ActiveLists.Last;
      if CurrentSet.Count > 0 then begin
        {$IFDEF CHECK_GRAPHS}
        B:=False;
        {$ENDIF}
        for I:=0 to ActiveList.Count - 1 do begin
          V:=ActiveList[I];
          GoodVertex:=True;
          for J:=0 to V.NeighbEdges.Count - 1 do
            if CurrentSet.IndexOf(V.Neighbour[J]) >= 0 then begin
              GoodVertex:=False;
              Break;
            end;
          if GoodVertex then begin
            {$IFDEF CHECK_GRAPHS}
            B:=True;
            {$ENDIF}
            Break;
          end;
        end;
        {$IFDEF CHECK_GRAPHS}
        if not B then
          Error(SAlgorithmFailure);
        {$ENDIF}
      end
      else
        V:=ActiveList[0];
      ExcludeNeighbours(ActiveLists); { Q+(k+1) = Q+(k) - [<������ V>] - [V] }
      ActiveLists.Last.Remove(V);
      ExcludeNeighbours(BackLists); { Q-(k+1) = Q-(k+1) - [<������ V>] }
      CurrentSet.Add(V);
      SelectedVertices.Push(V);
      { Inc(k) }
    Label3:
      { ���� ���������� �������, ������������� Q-(k), �����, ��� �� ���� ��
        �������-����� �� ������ � Q+(k), �� goto Label5, ����� goto Label4 }
      ActiveList:=ActiveLists.Last;
      BackList:=BackLists.Last;
      for I:=0 to BackList.Count - 1 do begin
        V:=BackList[I];
        GoodVertex:=True;
        if ActiveList.Count > 0 then
          for J:=0 to V.NeighbEdges.Count - 1 do
            if ActiveList.IndexOf(V.Neighbour[J]) >= 0 then begin
              GoodVertex:=False;
              Break;
            end;
        if GoodVertex then
          goto Label5;
      end;
   {Label4:}
      B1:=ActiveList.Count = 0;
      B2:=BackList.Count = 0;
      if B1 and B2 then begin
        { S �������� ������������ ����������� ���������� }
        Case SelectCode of
          SelectAnyMin:
            begin
              B1:=False;
              if CurrentSet.Count < ExtremumSize then begin
                ExtremumSize:=CurrentSet.Count;
                ExtremumSet.Assign(CurrentSet);
              end;
            end;
          SelectAnyMax:
            begin
              B1:=False;
              if CurrentSet.Count > ExtremumSize then begin
                ExtremumSize:=CurrentSet.Count;
                ExtremumSet.Assign(CurrentSet);
              end;
            end;
          SelectAllMin:
            begin
              B1:=False;
              if CurrentSet.Count <= ExtremumSize then begin
                if CurrentSet.Count < ExtremumSize then begin
                  ExtremumSize:=CurrentSet.Count;
                  ExtremumSets.Clear;
                end;
                ExtremumSets.AddAssign(CurrentSet);
              end;
            end;
          SelectAllMax:
            begin
              B1:=False;
              if CurrentSet.Count >= ExtremumSize then begin
                if CurrentSet.Count > ExtremumSize then begin
                  ExtremumSize:=CurrentSet.Count;
                  ExtremumSets.Clear;
                end;
                ExtremumSets.AddAssign(CurrentSet);
              end;
            end;
          SelectAllGE:
            B1:=CurrentSet.Count >= SelectParam;
          SelectAllLE:
            B1:=CurrentSet.Count <= SelectParam;
          Else
            B1:=True;
        End;
        if B1 then
          VertexSets.AddAssign(CurrentSet);
        if (SelectCode = SelectAny) or (SelectCode = SelectSpecified) and
          (VertexSets.Count >= SelectParam)
        then
          Exit;
      end
      else
        goto Label2;
    Label5:
      { Dec(k) }
      ActiveLists.Grow(-1);
      if (CurrentSet.Count > 0) or (ActiveLists.Count > 0) then begin
        BackLists.Grow(-1);
        V:=SelectedVertices.Pop;
        CurrentSet.Remove(V);
        ActiveLists.Last.Remove(V);
        BackLists.Last.Add(V);
        goto Label3;
      end
      else { ����� }
        if SelectCode in [SelectAnyMin, SelectAnyMax] then
          VertexSets.Add(ExtremumSet)
        else
          if SelectCode in [SelectAllMin, SelectAllMax] then
            VertexSets.Assign(ExtremumSets);
    finally
      CurrentSet.Free;
      ActiveLists.Free;
      BackLists.Free;
      SelectedVertices.Free;
      ExtremumSets.Free;
    end;
  end;
end;
{$IFDEF NOWARN}{$WARNINGS ON}{$ENDIF}

procedure TGraph.GetComplementOf(Source: TGraph);
var
  I, J: Integer;
  M: TBoolMatrix;
begin
  M:=Source.CreateConnectionMatrix;
  try
    if Source <> Self then begin
      Clear;
      AddVertices(Source.VertexCount);
    end
    else
      ClearEdges;
    for I:=0 to M.RowCount - 1 do
      for J:=M.StartOfRow(I) to M.ColCount - 1 do
        if not M[I, J] then
          AddEdgeI(I, J);
  finally
    M.Free;
  end;
end;

procedure TGraph.GetLineGraphOf(Source: TGraph);
var
  I, J, K, N, T1, T2: Integer;
  V: TVertex;
  B: TBoolMatrix;
begin
  {$IFDEF CHECK_GRAPHS}
  if Source = Self then Error(SErrorInParameters);
  {$ENDIF}
  Clear;
  N:=Source.EdgeCount;
  AddVertices(N);
  B:=TBoolMatrix.Create(N, N, False);
  try
    for I:=0 to Source.FVertices.Count - 1 do begin
      V:=Source.FVertices[I];
      N:=V.NeighbEdges.Count - 1;
      for J:=0 to N do begin
        T1:=TEdge(V.NeighbEdges[J]).Index;
        for K:=0 to N do
          if K <> J then begin
            T2:=TEdge(V.NeighbEdges[K]).Index;
            if not B[T1, T2] then begin
              AddEdgeI(T1, T2);
              B[T1, T2]:=True;
            end;
          end;
      end;
    end;
  finally
    B.Free;
  end;
end;

function TGraph.GetShortestSpanningTreeOf(Source: TGraph): Float;
var
  I: Integer;
  E1, E2: TEdge;
  SSTList: TClassList;
begin
  Clear;
  SSTList:=TClassList.Create;
  try
    Result:=Source.FindShortestSpanningTree(SSTList);
    AddVertices(Source.FVertices.Count);
    Features:=Features + [Weighted];
    for I:=0 to SSTList.Count - 1 do begin
      E1:=SSTList[I];
      E2:=AddEdgeI(E1.V1.Index, E1.V2.Index);
      E2.Weight:=E1.Weight;
      E2.FTemp.AsInt32:=E1.Index;
    end;
  finally
    SSTList.Free;
  end;
end;

procedure TGraph.SortVertices(CompareVertices: TCompareFunc);
var
  I: Integer;
begin
  FVertices.SortBy(CompareVertices);
  for I:=0 to FVertices.Count - 1 do TVertex(FVertices[I]).FIndex:=I;
end;

procedure TGraph.SortEdges(CompareEdges: TCompareFunc);
var
  I: Integer;
begin
  FEdges.SortBy(CompareEdges);
  for I:=0 to FEdges.Count - 1 do TEdge(FEdges[I]).FIndex:=I;
end;

procedure TGraph.SortVerticesByObject(CompareVertices: TCompareEvent);
var
  I: Integer;
begin
  FVertices.SortByObject(CompareVertices);
  for I:=0 to FVertices.Count - 1 do TVertex(FVertices[I]).FIndex:=I;
end;

procedure TGraph.SortEdgesByObject(CompareEdges: TCompareEvent);
var
  I: Integer;
begin
  FEdges.SortByObject(CompareEdges);
  for I:=0 to FEdges.Count - 1 do TEdge(FEdges[I]).FIndex:=I;
end;

procedure TGraph.GetVertices(VertexList: TClassList);
begin
  VertexList.Assign(FVertices);
end;

{ *** ������� }

function TGraph.GetArc(FromVertex, ToVertex: TVertex): TEdge;
var
  I: Integer;
begin
  {$IFDEF CHECK_GRAPHS}
  if not (Directed in Features) then Error(SMethodNotApplicable);
  {$ENDIF}
  if FromVertex <> nil then
    for I:=0 to FromVertex.NeighbEdges.Count - 1 do begin
      Result:=FromVertex.NeighbEdges[I];
      if (Result.V1 = FromVertex) and (Result.V2 = ToVertex) then
        Exit;
    end;
  Result:=nil;
end;

function TGraph.GetArcI(FromIndex, ToIndex: Integer): TEdge;
var
  N: Integer;
begin
  {$IFDEF CHECK_GRAPHS}
  if not (Directed in Features) then Error(SMethodNotApplicable);
  {$ENDIF}
  N:=FVertices.Count;
  if (FromIndex >= 0) and (FromIndex < N) and (ToIndex >= 0) and (ToIndex < N) then
    Result:=GetArc(FVertices[FromIndex], FVertices[ToIndex])
  else
    Result:=nil;
end;

procedure TGraph.GetArcs(ArcsList: TClassList; FromVertex, ToVertex: TVertex);
var
  I: Integer;
  E: TEdge;
begin
  {$IFDEF CHECK_GRAPHS}
  if not (Directed in Features) then Error(SMethodNotApplicable);
  {$ENDIF}
  ArcsList.Clear;
  if FromVertex <> nil then begin
    for I:=0 to FromVertex.NeighbEdges.Count - 1 do begin
      E:=FromVertex.NeighbEdges[I];
      if (E.V1 = FromVertex) and (E.V2 = ToVertex) then
        ArcsList.Add(E);
    end;
    ArcsList.Pack;
  end;
end;

procedure TGraph.GetArcsI(ArcsList: TClassList; FromIndex, ToIndex: Integer);
var
  N: Integer;
  FromVertex, ToVertex: TVertex;
begin
  {$IFDEF CHECK_GRAPHS}
  if not (Directed in Features) then Error(SMethodNotApplicable);
  {$ENDIF}
  N:=FVertices.Count;
  if (FromIndex >= 0) and (FromIndex < N) then
    FromVertex:=FVertices[FromIndex]
  else
    FromVertex:=nil;
  if (ToIndex >= 0) and (ToIndex < N) then
    ToVertex:=FVertices[ToIndex]
  else
    ToVertex:=nil;
  GetArcs(ArcsList, FromVertex, ToVertex);
end;

procedure TGraph.GetInArcsList(ArcsList: TMultiList);
var
  I, J, N: Integer;
  V: TVertex;
  E: TEdge;
  AList: TClassList;
begin
  {$IFDEF CHECK_GRAPHS}
  if not (Directed in Features) then Error(SMethodNotApplicable);
  {$ENDIF}
  N:=FVertices.Count;
  ArcsList.Count:=N;
  for I:=0 to N - 1 do begin
    AList:=ArcsList[I];
    AList.Clear;
    V:=FVertices[I];
    for J:=0 to V.NeighbEdges.Count - 1 do begin
      E:=V.NeighbEdges[J];
      if E.V2 = V then
        AList.Add(E);
    end;
    AList.Pack;
  end;
end;

procedure TGraph.GetOutArcsList(ArcsList: TMultiList);
var
  I, J, N: Integer;
  V: TVertex;
  E: TEdge;
  AList: TClassList;
begin
  {$IFDEF CHECK_GRAPHS}
  if not (Directed in Features) then Error(SMethodNotApplicable);
  {$ENDIF}
  N:=FVertices.Count;
  ArcsList.Count:=N;
  for I:=0 to N - 1 do begin
    AList:=ArcsList[I];
    AList.Clear;
    V:=FVertices[I];
    for J:=0 to V.NeighbEdges.Count - 1 do begin
      E:=V.NeighbEdges[J];
      if E.V1 = V then
        AList.Add(E);
    end;
    AList.Pack;
  end;
end;

function TGraph.FindStrongComponents(ComponentNumbers: TGenericIntegerVector): Integer;
var
  Counter1, Counter2: Integer;
  SearchNumbers: TIntegerVector;
  Roots: TClassList;
  Unfinished: TPointerStack;

  procedure Search(FromVertex: TVertex);
  var
    I, SearchNumber: Integer;
    V: TVertex;
    E: TEdge;
  begin
    Inc(Counter1);
    SearchNumbers.IncItem(FromVertex.Index, Counter1);
    Unfinished.Push(FromVertex);
    FromVertex.FTemp.AsInt32:=0;
    Roots.Add(FromVertex);
    for I:=0 to FromVertex.NeighbEdges.Count - 1 do begin
      E:=FromVertex.NeighbEdges[I];
      if E.V1 = FromVertex then begin
        V:=E.OtherVertex(FromVertex);
        SearchNumber:=SearchNumbers[V.Index];
        if SearchNumber = -1 then
          Search(V)
        else
          if V.FTemp.AsInt32 = 0 then { <=> Unfinished.IndexOf(V) >= 0 }
            while SearchNumbers[TVertex(Roots.Last).Index] > SearchNumber do
              Roots.Pop;
      end;
    end; {for}
    if FromVertex = Roots.Last then begin
      repeat
        V:=Unfinished.Pop;
        V.FTemp.AsInt32:=-1;
        if ComponentNumbers <> nil then
          ComponentNumbers[V.Index]:=Counter2;
      until FromVertex = V;
      Inc(Counter2);
      Roots.Pop;
    end;
  end;

var
  I: Integer;
begin
  {$IFDEF CHECK_GRAPHS}
  if not (Directed in Features) then Error(SMethodNotApplicable);
  {$ENDIF}
  Counter1:=0;
  Counter2:=0;
  SearchNumbers:=TIntegerVector.Create(FVertices.Count, -1);
  Roots:=TClassList.Create;
  Unfinished:=TPointerStack.Create;
  try
    if ComponentNumbers <> nil then
      ComponentNumbers.Count:=FVertices.Count;
    SetTempForVertices(-1);
    for I:=0 to FVertices.Count - 1 do
      if SearchNumbers[I] = -1 then
        Search(FVertices[I]);
  finally
    SearchNumbers.Free;
    Roots.Free;
    Unfinished.Free;
  end;
  Result:=Counter2;
end;

{ *** ������� }

function TGraph.GetRoot: TVertex;
begin
  {$IFDEF CHECK_GRAPHS}
  if not (Tree in Features) then Error(SMethodNotApplicable);
  {$ENDIF}
  Result:=AsPointer[GAttrRoot];
end;

procedure TGraph.SetRoot(Vertex: TVertex);
begin
  if Vertex <> nil then
    Vertex.IsRoot:=True
  else
    AsPointer[GAttrRoot]:=nil;
end;

procedure TGraph.CorrectTree;

  procedure DoCorrect(V: TVertex);
  var
    I: Integer;
    VTemp: Int32;
    Neighbour: TVertex;
  begin
    VTemp:=V.FTemp.AsInt32;
    for I:=0 to V.NeighbEdges.Count - 1 do begin
      Neighbour:=V.Neighbour[I];
      if Neighbour.FTemp.AsInt32 > VTemp then begin
        Neighbour.SafeSetParent(V);
        DoCorrect(Neighbour);
      end;
    end;
  end;

var
  V: TVertex;
begin
  {$IFDEF CHECK_GRAPHS}
  if not (Tree in Features) then Error(SMethodNotApplicable);
  {$ENDIF}
  if IsTree then begin
    V:=Root;
    if V <> nil then begin
      BFSFromVertex(V);
      DoCorrect(V);
    end
    else
      Error(STreeHasNoRoot);
  end
  else
    Error(SMethodNotApplicable);
end;

{ *** ������������ ���� }

function TGraph.GetNetworkSource: TVertex;
begin
  {$IFDEF CHECK_GRAPHS}
  if not (Network in Features) then Error(SMethodNotApplicable);
  {$ENDIF}
  Result:=AsPointer[GAttrNetworkSource];
end;

procedure TGraph.SetNetworkSource(Vertex: TVertex);
begin
  Vertex.IsNetworkSource:=True;
end;

function TGraph.GetNetworkSink: TVertex;
begin
  {$IFDEF CHECK_GRAPHS}
  if not (Network in Features) then Error(SMethodNotApplicable);
  {$ENDIF}
  Result:=AsPointer[GAttrNetworkSink];
end;

procedure TGraph.SetNetworkSink(Vertex: TVertex);
begin
  Vertex.IsNetworkSink:=True;
end;

function TGraph.IsNetworkCorrect: Bool;
var
  NwSrc, NwSink: TVertex;
begin
  NwSrc:=NetworkSource;
  NwSink:=NetworkSink;
  Result:=(NwSrc <> nil) and (NwSink <> nil) and (NwSrc <> NwSink) and
    (NwSrc.InDegree = 0) and (NwSink.OutDegree = 0) and Connected and
    not HasParallelEdges;
end;

type
  PFlowData = ^TFlowData;
  TFlowData = record
    TempFlow, TempMaxFlow: Float;
    { ������������ � ���������� ���������� ��� �������������, �� ��
      ������������� ��������� �������� ������������������, � ������� -
      ������������� ��������� ������������ ��-�� ������ ���������� }
    AllowForward, AllowBack: Bool;
  end;

{ ��� ��������� ������������� � ������ FindMaxFlowThroughNetwork ������
  ��������� ������������ ������������ ���������� }

function TGraph.FindMaxFlowAcceptEdge(Edge: TEdge; FromVertex: TVertex): Bool;
begin
  With PFlowData(Edge.FTemp.AsPointer)^ do
    if Edge.V1 = FromVertex then
      Result:=AllowForward{TempFlow < TempMaxFlow}
    else
      Result:=AllowBack{TempFlow > 0};
end;

function TGraph.FindMaxFlowThroughNetwork: Float;
var
  I, IMaxIncrease: Integer;
  F, MaxIncrease: Float;
  P: PFlowData;
  NwSrc, NwSink, V: TVertex;
  E: TEdge;
  EdgePath: TClassList;
begin
  if not IsNetworkCorrect then
    Error(SMethodNotApplicable);
  NwSrc:=NetworkSource;
  NwSink:=NetworkSink;
  for I:=0 to FEdges.Count - 1 do begin
    E:=FEdges[I];
    New(P);
    With P^ do begin
      TempFlow:=0;
      TempMaxFlow:=E.AsFloat[GAttrMaxFlow];
      AllowForward:=0 < TempMaxFlow;
      AllowBack:=False;
    end;
    E.FTemp.AsPointer:=P;
  end;
  EdgePath:=TClassList.Create;
  try
    while FindMinPathCond(NwSrc, NwSink, nil, FindMaxFlowAcceptEdge,
      EdgePath) >= 0 do { � ������� ���������� ������ �������� ���� }
    begin
      { ����������� ����� ����� ���������� ����, ��������� ��������, ��������
        ����� ����� �����, ���������� � �������� �����������, � ���������� -
        � ������ }
      MaxIncrease:=MaxFloat;
      IMaxIncrease:=0;
      V:=NwSrc;
      for I:=0 to EdgePath.Count - 1 do begin
        E:=EdgePath[I];
        With PFlowData(E.FTemp.AsPointer)^ do
          if V = E.V1 then begin { ����� �������� � ������ ����������� }
            F:=TempMaxFlow - TempFlow;
            if F < MaxIncrease then begin
              MaxIncrease:=F;
              IMaxIncrease:=I;
            end;
          end
          else { ����� �������� � �������� ����������� }
            if TempFlow < MaxIncrease then begin
              MaxIncrease:=TempFlow;
              IMaxIncrease:=I;
            end;
        V:=E.OtherVertex(V);
      end; {for}
      V:=NwSrc;
      for I:=0 to EdgePath.Count - 1 do begin
        E:=EdgePath[I];
        With PFlowData(E.FTemp.AsPointer)^ do begin
          if V = E.V1 then
            TempFlow:=TempFlow + MaxIncrease
          else
            TempFlow:=TempFlow - MaxIncrease;
          if I <> IMaxIncrease then begin
            AllowForward:=TempFlow < TempMaxFlow;
            AllowBack:=TempFlow > 0;
          end
          else { ���������� �� ������������ }
            if V = E.V1 then
              AllowForward:=False
            else
              AllowBack:=False;
        end;
        V:=E.OtherVertex(V);
      end; {for}
    end;
  finally
    Result:=0;
    for I:=0 to NwSink.NeighbEdges.Count - 1 do
      Result:=Result + PFlowData(TEdge(NwSink.NeighbEdges[I]).FTemp.AsPointer)^.TempFlow;
    for I:=0 to FEdges.Count - 1 do begin
      E:=FEdges[I];
      E.AsFloat[GAttrFlow]:=PFlowData(E.FTemp.AsPointer)^.TempFlow;
      Dispose(PFlowData(E.FTemp.AsPointer));
    end;
    EdgePath.Free;
  end;
end;

{ *** ���������� ����� }

procedure TGraph.Dijkstra(Vertex1, Vertex2: TVertex; AcceptVertex: TAcceptVertex;
  AcceptEdge: TAcceptEdge; Distances: TFloatVector);
var
  I, WeightOffset, NeighbIndex: Integer;
  VDistance, T: Float;
  V, Neighbour: TVertex;
  E: TEdge;
  NodeList: TClassList;
  PriorityQueue: TFloatPriorityQueue;
  Allowed: TBoolVector;
  { ������������� Allowed �������� �������� ������ �, ����� ����, ��� ������� �
    ����� ����� � �������������� ������ � ����������� �������� CHECK_GRAPHS
    ������������ �� Access Violation (�� �� ����������� ���������� ������!) }
begin
  {$IFDEF CHECK_GRAPHS}
  for I:=0 to FEdges.Count - 1 do
    if TEdge(FEdges[I]).Weight < 0 then
      Error(SMethodNotApplicable);
  {$ENDIF}
  WeightOffset:=FEdgeAttrMap.Offset(GAttrWeight);
  SetTempForVertices(Int32(nil));
  PriorityQueue:=TFloatPriorityQueue.Create;
  NodeList:=TClassList.Create;
  Allowed:=nil;
  try
    NodeList.Count:=FVertices.Count;
    Allowed:=TBoolVector.Create(FVertices.Count, True);
    Distances[Vertex1.Index]:=0;
    V:=Vertex1;
    repeat
      VDistance:=Distances[V.Index];
      Allowed[V.Index]:=False;
      for I:=0 to V.NeighbEdges.Count - 1 do begin
        E:=V.NeighbEdges[I];
        if not Assigned(AcceptEdge) or AcceptEdge(E, V) then begin
          Neighbour:=E.OtherVertex(V);
          NeighbIndex:=Neighbour.Index;
          if Allowed[NeighbIndex] and
            (not Assigned(AcceptVertex) or AcceptVertex(Neighbour)) then
          begin
            T:=VDistance + E.AsFloatByOfs[WeightOffset]; { E.Weight }
            if T < Distances[NeighbIndex] then begin
              Neighbour.FTemp.AsPointer:=E;
              Distances[NeighbIndex]:=T;
              NodeList[NeighbIndex]:=PriorityQueue.ChangeNodePriority(
                NodeList[NeighbIndex], Neighbour, T);
            end;
          end;
        end;
      end; {for}
      if PriorityQueue.IsEmpty then
        Break;
      V:=PriorityQueue.DeleteMin;
    until V = Vertex2;
  finally
    PriorityQueue.Free;
    NodeList.Free;
    Allowed.Free;
  end;
end;

function TGraph.FindMinWeightPathCond(Vertex1, Vertex2: TVertex;
  AcceptVertex: TAcceptVertex; AcceptEdge: TAcceptEdge;
  EdgePath: TClassList): Float;
var
  E: TEdge;
  Distances: TFloatVector;
begin
  if EdgePath <> nil then
    EdgePath.Clear;
  if Vertex1 <> Vertex2 then begin
    Result:=-1;
    if not (gsValidSeparates in FStates) or
      (Vertex1.SeparateIndex = Vertex2.SeparateIndex) then
    begin { ������������ ������������ �������� �������� }
      Distances:=TFloatVector.Create(FVertices.Count, MaxFloat);
      try
        Dijkstra(Vertex1, Vertex2, AcceptVertex, AcceptEdge, Distances);
        if Distances[Vertex2.Index] < MaxFloat then begin
          Result:=Distances[Vertex2.Index];
          if EdgePath <> nil then begin
            repeat
              E:=Vertex2.FTemp.AsPointer;
              EdgePath.Add(E);
              Vertex2:=E.OtherVertex(Vertex2);
            until Vertex2 = Vertex1;
            EdgePath.Pack;
            EdgePath.Reverse;
          end;
        end;
      finally
        Distances.Free;
      end;
    end;
  end
  else
    Result:=0;
end;

function TGraph.FindMinWeightPath(Vertex1, Vertex2: TVertex;
  EdgePath: TClassList): Float;
begin
  if Directed in Features then
    Result:=FindMinWeightPathCond(Vertex1, Vertex2, nil, AcceptArc, EdgePath)
  else
    Result:=FindMinWeightPathCond(Vertex1, Vertex2, nil, nil, EdgePath);
end;

procedure TGraph.FindDistancesCond(FromVertex: TVertex; AcceptVertex: TAcceptVertex;
  AcceptEdge: TAcceptEdge; Distances: TFloatVector);
begin
  Distances.Count:=FVertices.Count;
  Distances.FillValue(MaxFloat);
  Dijkstra(FromVertex, nil, AcceptVertex, AcceptEdge, Distances);
end;

procedure TGraph.FindDistances(FromVertex: TVertex; Distances: TFloatVector);
begin
  if Directed in Features then
    FindDistancesCond(FromVertex, nil, AcceptArc, Distances)
  else
    FindDistancesCond(FromVertex, nil, nil, Distances);
end;

function TGraph.CreateWeightsMatrix: TFloatMatrix;
var
  I, Index1, Index2, WeightOffset: Integer;
  T: Float;
  E: TEdge;
begin
  {$IFDEF CHECK_GRAPHS}
  if not (Weighted in Features) then Error(SMethodNotApplicable);
  {$ENDIF}
  WeightOffset:=FEdgeAttrMap.Offset(GAttrWeight);
  I:=FVertices.Count;
  if Directed in Features then
    Result:=TFloatMatrix.Create(I, I, MaxFloat)
  else
    Result:=TSimFloatMatrix.Create(I, MaxFloat);
  try
    for I:=0 to FEdges.Count - 1 do begin
      { ���� ������� ��������� ����� ��� ����� ������ (�����), ��
        �������� ����� (����) � ����������� ����� }
      E:=FEdges[I];
      Index1:=E.V1.Index;
      Index2:=E.V2.Index;
      T:=E.AsFloatByOfs[WeightOffset]; { E.Weight }
      if T < Result[Index1, Index2] then
        Result[Index1, Index2]:=T;
    end;
  except
    Result.Free;
    raise;
  end;
end;

function TGraph.CreateMinWeightPathsMatrix(var DistancesMatrix: TFloatMatrix;
  PathsMatrix: TIntegerMatrix): Bool;

  function StartOfRow(Row: Integer): Integer;
  begin
    if PathsMatrix <> nil then
      Result:=0
    else
      Result:=DistancesMatrix.StartOfRow(Row);
  end;

var
  I, J, K, N: Integer;
  R, S, T: Float;
  NewMatrix: TFloatMatrix;
begin
  {$IFDEF CHECK_GRAPHS}
  if not (Weighted in Features) then Error(SMethodNotApplicable);
  {$ENDIF}
  { ������� ������� ����� ����� (���) }
  N:=FVertices.Count;
  if PathsMatrix <> nil then begin
    PathsMatrix.SetSize(N, N);
    for I:=0 to N - 1 do
      for J:=0 to N - 1 do
        PathsMatrix[I, J]:=I;
  end;
  DistancesMatrix:=CreateWeightsMatrix;
  try
    if Directed in Features then
      NewMatrix:=TFloatMatrix.Create(N, N, MaxFloat)
    else
      NewMatrix:=TSimFloatMatrix.Create(N, MaxFloat);
    try
      { �������� ���� }
      Dec(N);
      for K:=0 to N do begin
        for I:=0 to N do
          if I <> K then
            for J:=StartOfRow(I) to N do
              if J <> K then begin
                R:=DistancesMatrix[I, K];
                S:=DistancesMatrix[K, J];
                T:=DistancesMatrix[I, J];
                if (R < MaxFloat) and (S < MaxFloat) then begin
                  R:=R + S;
                  if R < T then
                    if I <> J then begin
                      NewMatrix[I, J]:=R;
                      if PathsMatrix <> nil then
                        PathsMatrix[I, J]:=PathsMatrix[K, J];
                    end
                    else
                      if R < 0 then begin
                        DistancesMatrix[I, J]:=R;
                        Result:=False;
                        Exit;
                      end
                      else
                  else
                    NewMatrix[I, J]:=T;
                end
                else
                  NewMatrix[I, J]:=T;
              end
              else
                NewMatrix[I, J]:=DistancesMatrix[I, J]
          else
            for J:=DistancesMatrix.StartOfRow(I) to N do
              NewMatrix[I, J]:=DistancesMatrix[I, J];
        DistancesMatrix.Assign(NewMatrix);
      end; {for K}
      Result:=True;
    finally
      NewMatrix.Free;
    end;
  except
    DistancesMatrix.Free;
    DistancesMatrix:=nil;
    raise;
  end;
end;

function TGraph.DecodeMinWeightPath(WeightMatrix: TFloatMatrix;
  PathsMatrix: TIntegerMatrix; I, J: Integer;
  VertexIndexes: TGenericIntegerVector): Bool;
begin
  VertexIndexes.Clear;
  if WeightMatrix[I, J] < MaxFloat then begin
    repeat
      VertexIndexes.Add(J);
      J:=PathsMatrix[I, J];
    until I = J;
    VertexIndexes.Add(I);
    VertexIndexes.Pack;
    VertexIndexes.Reverse;
    Result:=True;
  end
  else
    Result:=False;
end;

function TGraph.FindShortestSpanningTree(SSTList: TClassList): Float;
var
  I, N, NeighbIndex: Integer;
  T: Float;
  V, Neighbour: TVertex;
  E: TEdge;
  PriorityQueue: TFloatPriorityQueue;
  Distances: TFloatVector;
  NodeList: TClassList;
begin
  {$IFDEF CHECK_GRAPHS}
  if not (Weighted in Features) then Error(SMethodNotApplicable);
  {$ENDIF}
  Result:=0;
  if SSTList <> nil then
    SSTList.Clear;
  N:=FVertices.Count;
  if N > 1 then begin
    PriorityQueue:=TFloatPriorityQueue.Create;
    Distances:=nil;
    NodeList:=nil;
    try
      Distances:=TFloatVector.Create(N, MaxFloat);
      NodeList:=TClassList.Create;
      NodeList.Count:=N;
      for I:=0 to N - 1 do
        NodeList[I]:=PriorityQueue.Add(FVertices[I], MaxFloat);
      if SSTList <> nil then
        SSTList.Capacity:=N - 1;
      SetTempForVertices(Int32(nil));
      while not PriorityQueue.IsEmpty do begin
        V:=PriorityQueue.DeleteMin;
        if Distances[V.Index] <> MaxFloat then begin
          E:=V.FTemp.AsPointer;
          if SSTList <> nil then
            SSTList.Add(E);
          Result:=Result + E.Weight;
        end;
        Distances[V.Index]:=-MaxFloat;
        for I:=0 to V.NeighbEdges.Count - 1 do begin
          E:=V.NeighbEdges[I];
          Neighbour:=E.OtherVertex(V);
          NeighbIndex:=Neighbour.Index;
          T:=E.Weight;
          if T < Distances[NeighbIndex] then begin
            NodeList[NeighbIndex]:=PriorityQueue.ChangeNodePriority(
              NodeList[NeighbIndex], Neighbour, T);
            Distances[NeighbIndex]:=T;
            Neighbour.FTemp.AsPointer:=E;
          end;
        end;
      end;
    finally
      PriorityQueue.Free;
      Distances.Free;
      NodeList.Free;
    end;
    if SSTList <> nil then
      SSTList.Pack;
  end;
end;

{ *** �������������� ����� }

procedure TGraph.GetExtent2D(var MinX, MaxX, MinY, MaxY: Float);
var
  I, XOffset, YOffset: Integer;
  X1, Y1: Float;
  V: TVertex;
begin
  {$IFDEF CHECK_GRAPHS}
  if not (Geom2D in Features) then Error(SMethodNotApplicable);
  {$ENDIF}
  XOffset:=FVertexAttrMap.Offset(GAttrX);
  YOffset:=FVertexAttrMap.Offset(GAttrY);
  MinX:=MaxFloat;
  MaxX:=-MaxFloat;
  MinY:=MaxFloat;
  MaxY:=-MaxFloat;
  for I:=0 to FVertices.Count - 1 do begin
    V:=FVertices[I];
    X1:=V.AsFloatByOfs[XOffset];
    if X1 < MinX then
      MinX:=X1;
    if X1 > MaxX then
      MaxX:=X1;
    Y1:=V.AsFloatByOfs[YOffset];
    if Y1 < MinY then
      MinY:=Y1;
    if Y1 > MaxY then
      MaxY:=Y1;
  end;
end;

procedure TGraph.GetExtent3D(var MinX, MaxX, MinY, MaxY, MinZ, MaxZ: Float);
var
  I, XOffset, YOffset, ZOffset: Integer;
  X1, Y1, Z1: Float;
  V: TVertex;
begin
  {$IFDEF CHECK_GRAPHS}
  if not (Geom3D in Features) then Error(SMethodNotApplicable);
  {$ENDIF}
  XOffset:=FVertexAttrMap.Offset(GAttrX);
  YOffset:=FVertexAttrMap.Offset(GAttrY);
  ZOffset:=FVertexAttrMap.Offset(GAttrZ);
  MinX:=MaxFloat;
  MaxX:=-MaxFloat;
  MinY:=MaxFloat;
  MaxY:=-MaxFloat;
  MinZ:=MaxFloat;
  MaxZ:=-MaxFloat;
  for I:=0 to FVertices.Count - 1 do begin
    V:=FVertices[I];
    X1:=V.AsFloatByOfs[XOffset];
    if X1 < MinX then
      MinX:=X1;
    if X1 > MaxX then
      MaxX:=X1;
    Y1:=V.AsFloatByOfs[YOffset];
    if Y1 < MinY then
      MinY:=Y1;
    if Y1 > MaxY then
      MaxY:=Y1;
    Z1:=V.AsFloatByOfs[ZOffset];
    if Z1 < MinZ then
      MinZ:=Z1;
    if Z1 > MaxZ then
      MaxZ:=Z1;
  end;
end;

{$IFDEF NOWARN}{$WARNINGS OFF}{$ENDIF}
procedure TGraph.AssignCoordinates(Source: TGraph);
var
  I, XOffset, YOffset, ZOffset, SrcXOffset, SrcYOffset, SrcZOffset, Min: Integer;
  D3: Bool;
  V, SrcV: TVertex;
begin
  {$IFDEF CHECK_GRAPHS}
  if not (Geom2D in Features) and (Geom2D in Source.Features) then
    Error(SMethodNotApplicable);
  {$ENDIF}
  XOffset:=FVertexAttrMap.Offset(GAttrX);
  YOffset:=FVertexAttrMap.Offset(GAttrY);
  SrcXOffset:=Source.FVertexAttrMap.Offset(GAttrX);
  SrcYOffset:=Source.FVertexAttrMap.Offset(GAttrY);
  D3:=(Geom3D in Features) and (Geom3D in Source.Features);
  if D3 then begin
    ZOffset:=FVertexAttrMap.Offset(GAttrZ);
    SrcZOffset:=Source.FVertexAttrMap.Offset(GAttrZ);
  end;
  Min:=Source.FVertices.Count;
  if FVertices.Count < Min then
    Min:=FVertices.Count;
  for I:=0 to Min - 1 do begin
    V:=FVertices[I];
    SrcV:=Source.FVertices[I];
    V.AsFloatByOfs[XOffset]:=SrcV.AsFloatByOfs[SrcXOffset];
    V.AsFloatByOfs[YOffset]:=SrcV.AsFloatByOfs[SrcYOffset];
    if D3 then
      V.AsFloatByOfs[ZOffset]:=SrcV.AsFloatByOfs[SrcZOffset];
  end;
end;
{$IFDEF NOWARN}{$WARNINGS ON}{$ENDIF}

procedure TGraph.GetCoords2D(XCoords, YCoords: TFloatVector);
var
  I, N, XOffset, YOffset: Integer;
begin
  {$IFDEF CHECK_GRAPHS}
  if not (Geom2D in Features) then Error(SMethodNotApplicable);
  {$ENDIF}
  N:=FVertices.Count;
  XCoords.Count:=N;
  YCoords.Count:=N;
  XOffset:=FVertexAttrMap.Offset(GAttrX);
  YOffset:=FVertexAttrMap.Offset(GAttrY);
  for I:=0 to N - 1 do With TVertex(FVertices[I]) do begin
    XCoords[I]:=AsFloatByOfs[XOffset];
    YCoords[I]:=AsFloatByOfs[YOffset];
  end;
end;

procedure TGraph.GetCoords3D(XCoords, YCoords, ZCoords: TFloatVector);
var
  I, N, ZOffset: Integer;
begin
  {$IFDEF CHECK_GRAPHS}
  if not (Geom3D in Features) then Error(SMethodNotApplicable);
  {$ENDIF}
  GetCoords2D(XCoords, YCoords);
  N:=FVertices.Count;
  ZCoords.Count:=N;
  ZOffset:=FVertexAttrMap.Offset(GAttrZ);
  for I:=0 to N - 1 do
    ZCoords[I]:=TVertex(FVertices[I]).AsFloatByOfs[ZOffset];
end;

procedure TGraph.SetCoords2D(XCoords, YCoords: TFloatVector);
var
  I, XOffset, YOffset: Integer;
begin
  {$IFDEF CHECK_GRAPHS}
  if not (Geom2D in Features) then Error(SMethodNotApplicable);
  {$ENDIF}
  XOffset:=FVertexAttrMap.Offset(GAttrX);
  YOffset:=FVertexAttrMap.Offset(GAttrY);
  for I:=0 to FVertices.Count - 1 do With TVertex(FVertices[I]) do begin
    AsFloatByOfs[XOffset]:=XCoords[I];
    AsFloatByOfs[YOffset]:=YCoords[I];
  end;
end;

procedure TGraph.SetCoords3D(XCoords, YCoords, ZCoords: TFloatVector);
var
  I, ZOffset: Integer;
begin
  {$IFDEF CHECK_GRAPHS}
  if not (Geom3D in Features) then Error(SMethodNotApplicable);
  {$ENDIF}
  SetCoords2D(XCoords, YCoords);
  ZOffset:=FVertexAttrMap.Offset(GAttrZ);
  for I:=0 to FVertices.Count - 1 do
    TVertex(FVertices[I]).AsFloatByOfs[ZOffset]:=ZCoords[I];
end;

end.
