export interface MessageDTO {
  id: string;
  senderId: string;
  senderName: string;
  message: string;
  created: Date;
}

export interface ChatDTO {
  id: string;
  engagementId: string;
  name: string;
  lastMessage: MessageDTO | null;
  seen: boolean;
  messages: MessageDTO[];
}

export interface MessageStreamDTO {
  conversationId: string;
  message: MessageDTO;
}

export interface ClientDTO extends CompanyExtended {
  id: string;
  relationId: string;
  name: string;
  cvr: string;
  phone: string;
  email: string;
  owner: string;
  ceo: string;
  address: string;
  vat: boolean;
  annualReport: boolean;
  payroll: boolean;
  kyc: boolean;
  tasks: TaskDTO[];
  attachments: FileDTO[];
}

interface CompanyBase {
  id: string;
  name: string;
}

interface FirmWithRole extends CompanyBase {
  role: FirmRole;
}

interface CompanyExtended extends CompanyBase {
  cvr: string;
  phone: string;
  email: string;
  owner: string;
  ceo: string;
  address: string;
}

export interface FirmDTO extends CompanyExtended {
  id: string;
  name: string;
  cvr: string;
  phone: string;
  email: string;
  owner: string;
  ceo: string;
  address: string;
  relations: EngagementTaskDTO[];
}

export interface FirmLightDTO extends CompanyExtended {
  id: string;
  name: string;
  cvr: string;
  email: string;
  phone: string;
  owner: string;
  ceo: string;
  address: string;
}

export interface FirmSettingsDTO extends CompanyExtended {
  name: string;
  id: string;
  users: FirmUserDTO[];
  tasks: TaskWithClientDTO[];
  cvr: string;
  email: string;
  phone: string;
  owner: string;
  ceo: string;
  address: string;
}

export interface MyFirmDTO extends FirmWithRole {
  id: string;
  name: string;
  role: FirmRole;
}

export interface EngagementDTO {
  firm: FirmLightDTO;
  clients: ClientDTO[];
}

export interface EngagementTaskDTO {
  id: string;
  firmId: string;
  clientId: string;
  tasks: TaskDTO[];
}

export interface FileDTO {
  id: string;
  filename: string;
  fileExtension: string;
  archived: boolean;
  size: number;
}

export interface TaskDTO {
  id: string;
  status: string;
  taskType: string;
  createdAt: Date;
  dueDate: Date | null;
  archived: boolean;
  hasFile: boolean | null;
}

export interface TaskWithClientDTO {
  id: string;
  clientId: string;
  clientName: string;
  status: string;
  taskType: string;
  createdAt: Date;
  dueDate: Date | null;
  archived: boolean;
  hasFile: boolean | null;
}

export interface CompanyTimerDTO {
  id: string;
  name: string;
  timers: TimerDTO[];
}

export interface TimerDTO {
  id: string;
  start: Date;
  end: Date | null;
}

export interface FirmUserDTO extends FirmUserBase {
  id: string;
  name: string;
  username: string;
  role: FirmRole;
}

export interface KeycloakUserDTO extends KeycloakUserBase {
  id: string;
  name: string;
  username: string;
  role: UserRole;
}

export interface PermissionUserDTO {
  id: string;
  name: string;
  username: string;
  role: FirmRole;
  vat: boolean;
  annualReport: boolean;
  payroll: boolean;
  kyc: boolean;
}

interface UserBase<R> {
  id: string;
  name: string;
  username: string;
  role: R;
}

interface KeycloakUserBase extends UserBase<UserRole> {
}

interface FirmUserBase extends UserBase<FirmRole> {
}
